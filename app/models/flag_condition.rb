include ActionView::Helpers::NumberHelper

class FlagCondition < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites
  has_many :flag_logs, :dependent => :destroy

  validate :accuracy_and_post_count


  def accuracy_and_post_count
    posts = Post.joins(:reasons).group('posts.id').where('posts.user_reputation <= ?', max_poster_rep).having('count(reasons.id) >= ?', min_reason_count).having('sum(reasons.weight) >= ?', min_weight)
    post_feedback_results = posts.pluck(:is_tp)
    true_positive_count = post_feedback_results.count(true)

    accuracy = true_positive_count.to_f * 100 / post_feedback_results.count.to_f

    if accuracy < FlagSetting["min_accuracy"].to_f
      errors.add(:accuracy, "must be over #{number_to_percentage(FlagSetting["min_accuracy"].to_f, precision: 2)}")
    end

    if post_feedback_results.count < FlagSetting["min_post_count"].to_i
      errors.add(:post_count, "must be over  #{FlagSetting["min_post_count"]}")
    end
  end

end
