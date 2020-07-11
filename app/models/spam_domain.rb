# frozen_string_literal: true

class SpamDomain < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :posts, after_add: :setup_review
  has_and_belongs_to_many :domain_tags, after_add: :check_dq
  has_and_belongs_to_many :domain_groups
  has_one :review_item, as: :reviewable
  has_many :abuse_reports, as: :reportable
  has_many :left_links, class_name: 'DomainLink', foreign_key: :left_id
  has_many :right_links, class_name: 'DomainLink', foreign_key: :right_id

  validates :domain, uniqueness: true

  after_create :fix_asn_tags

  def fix_asn_tags
    asn_query = `dig +short "$(dig +short '#{domain.tr("'", '')}' | awk -F. '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $4"."$3"." $2"."$1;exit}').origin.asn.cymru.com" TXT` # rubocop:disable Metrics/LineLength
    asn = asn_query.strip.tr('"', '').split('|')[0]&.strip
    return unless asn.present?
    prev_domain_tags = domain_tags.where(special: true).select(:name).map(&:name).select { |dt| dt.start_with?('AS-') }.map(&:name)
    asn.split.each do |as|
      desc = `dig +short AS#{as}.asn.cymru.com TXT`.strip.tr('"', '').split('|')[-1]&.strip
      tag = DomainTag.find_or_create_by(name: "AS-#{as}", special: true)
      prev_domain_tags -= ["AS-#{as}"]
      tag.update(description: "Domains under the Autonomous System Number #{as} - #{desc}.") unless tag.description.present?
      domain_tags << tag
    end
    prev_domain_tags.each do |dtn|
      domain_tags.delete(DomainTag.find_by(name: dtn))
    end
  end

  after_create do
    groups = Rails.cache.fetch 'domain_groups' do
      DomainGroup.all.map { |dg| !dg.regex ? nil : [Regexp.new(dg.regex), dg.id] }.compact.to_h
    end
    groups.keys.each do |r|
      DomainGroup.find(groups[r]).spam_domains << self if r.match? domain
    end
  end

  def links
    left_links.or right_links
  end

  def linked_domains
    SpamDomain.where(id: links.select(Arel.sql("IF(left_id = #{id}, right_id, left_id)")))
  end

  def should_dq?(_item)
    domain_tags.count > 0
  end

  def review_item_name
    domain
  end

  def post_counts
    Rails.cache.fetch "spam_domain_post_counts_##{id}" do
      { all: posts.count, tp: posts.where(is_tp: true).count, naa: posts.where(is_naa: true).count, fp: posts.where(is_fp: true).count }
    end
  end

  def self.preload_post_counts(domains)
    domains = domains.reject { |d| Rails.cache.exist? "spam_domain_post_counts_##{d.id}" }
    SpamDomain.joins(:posts).select(Arel.sql('spam_domains.id'),
                                    Arel.sql('COUNT(DISTINCT posts.id) AS all_count'),
                                    Arel.sql('COUNT(DISTINCT IF(posts.is_tp = TRUE, posts.id, NULL)) AS tp_count'),
                                    Arel.sql('COUNT(DISTINCT IF(posts.is_naa = TRUE, posts.id, NULL)) AS naa_count'),
                                    Arel.sql('COUNT(DISTINCT IF(posts.is_fp = TRUE, posts.id, NULL)) AS fp_count'))
              .group(Arel.sql('spam_domains.id')).where(spam_domains: { id: domains.map(&:id) }).each do |d|
      Rails.cache.write "spam_domain_post_counts_##{d.id}",
                        all: d.all_count, tp: d.tp_count, naa: d.naa_count, fp: d.fp_count
    end
  end

  private

  def setup_review(*_args)
    return unless posts.count >= 3 && domain_tags.count == 0 && !review_item.present?
    if posts.map(&:is_fp).any?(&:!)
      ReviewItem.create(reviewable: self, queue: ReviewQueue['untagged-domains'], completed: false)
    else
      domain_tags << DomainTag.find_or_create_by(name: 'notspam')
    end
  end

  def check_dq(*_args)
    return unless review_item.present? && should_dq?(review_item)
    review_item.update(completed: true)
  end
end
