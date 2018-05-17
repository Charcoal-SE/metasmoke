# frozen_string_literal: true

class AddUntaggedSpamDomainsReviewQueue < ActiveRecord::Migration[5.2]
  def change
    q = ReviewQueue.create name: 'untagged-domains', privileges: 'core', responses: [["I'm Done", 'done']],
                           description: 'Review and add tags to domains that have been seen a few times.'

    SpamDomain.joins(:posts).left_joins(:domain_tags).group(Arel.sql('spam_domains.id')).having(Arel.sql('COUNT(DISTINCT posts.id) >= 3'))
              .where(domain_tags: { id: nil }).each do |d|
      ReviewItem.create(reviewable: d, queue: q, completed: false)
    end
  end
end
