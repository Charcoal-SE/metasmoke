include ActionView::Helpers::NumberHelper

class FlagCondition < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites
  has_many :flag_logs, dependent: :nullify

  validate :accuracy_and_post_count


  def accuracy_and_post_count
    if flags_enabled
      post_feedback_results = posts.pluck(:is_tp)
      true_positive_count = post_feedback_results.count(true)

      accuracy = true_positive_count.to_f * 100 / post_feedback_results.count.to_f

      if accuracy < FlagSetting['min_accuracy'].to_f
        errors.add(:accuracy, "must be over #{number_to_percentage(FlagSetting['min_accuracy'].to_f, precision: 2)}")
      end

      if post_feedback_results.count < FlagSetting['min_post_count'].to_i
        errors.add(:post_count, "must be over  #{FlagSetting['min_post_count']}")
      end
    end
  end

  def self.revalidate_all
    FlagCondition.where(flags_enabled: true).each do |fc|
      unless fc.validate
        fc.flags_enabled = false
        fc.save!
      end
    end
  end

  def validate!(post)
    post.reasons.pluck(:weight).reduce(:+) >= self.min_weight &&
    post.stack_exchange_user.reputation <= self.max_poster_rep &&
    post.reasons.count >= self.min_reason_count
  end

  def posts
    Post.joins(:reasons).group('posts.id').where('posts.user_reputation <= ?', max_poster_rep).where(site_id: site_ids).having('count(reasons.id) >= ?', min_reason_count).having('sum(reasons.weight) >= ?', min_weight)
  end
end
