# frozen_string_literal: true

include ActionView::Helpers::NumberHelper

class FlagCondition < ApplicationRecord
  include Websocket

  belongs_to :user
  has_and_belongs_to_many :sites
  has_many :flag_logs, dependent: :nullify

  validate :accuracy_and_post_count

  def accuracy_and_post_count
    return unless flags_enabled
    post_feedback_results = posts.pluck(:is_tp)

    if accuracy < FlagSetting['min_accuracy'].to_f
      errors.add(:accuracy, "must be over #{number_to_percentage(FlagSetting['min_accuracy'].to_f, precision: 2)}")
    end

    return unless post_feedback_results.count < FlagSetting['min_post_count'].to_i
    errors.add(:post_count, "must be over  #{FlagSetting['min_post_count']}")
  end

  def accuracy
    post_feedback_results = posts.pluck(:is_tp)
    true_positive_count = post_feedback_results.count(true)

    true_positive_count.to_f * 100 / post_feedback_results.count.to_f
  end

  def self.revalidate_all
    FlagCondition.where(flags_enabled: true).find_each do |fc|
      unless fc.validate
        failures = fc.errors.full_messages
        fc.flags_enabled = false
        fc.save(validate: false)
        ActionCable.server.broadcast 'smokedetector_messages',
                                     message: "@#{fc.user&.username&.tr(' ', '')} " \
                                                "Your flag condition was disabled: #{failures.join(',')}"
      end
    end
  end

  def self.overall_accuracy(user)
    query = File.read(Rails.root.join('lib/queries/overall_accuracy.sql'))
    sanitized = ActiveRecord::Base.sanitize_sql([query, user_id: user.id])
    result = ActiveRecord::Base.connection.execute sanitized
    result.to_a[0][0]
  end

  def self.validate_for_user(user, disabler)
    accuracy = overall_accuracy user

    unless accuracy.present? && accuracy < FlagSetting['min_accuracy'].to_f #
      return accuracy
    end

    user.flag_conditions.update_all(flags_enabled: false)
    username = user&.username&.tr(' ', '')
    admin = disabler&.username&.tr(' ', '')
    SmokeDetector.send_message_to_charcoal "@#{username} Your flag conditions were manually disabled by @#{admin}: " \
                                           "Total accuracy must be >= #{FlagSetting['min_accuracy']}%."
    accuracy
  end

  def validate_weight_rep_reason_count!(weight, poster_rep, reason_count)
    weight >= min_weight && poster_rep <= max_poster_rep && reason_count >= min_reason_count
  end

  def validate!(post)
    validate_weight_rep_reason_count!(post.reasons.pluck(:weight).reduce(:+),
                                      post.stack_exchange_user.reputation,
                                      post.reasons.count)
  end

  def posts
    Post.joins(:reasons)
        .group(Arel.sql('posts.id'))
        .where('posts.user_reputation <= ?', max_poster_rep)
        .where(site_id: site_ids)
        .having('count(reasons.id) >= ?', min_reason_count)
        .having('sum(reasons.weight) >= ?', min_weight)
  end
end
