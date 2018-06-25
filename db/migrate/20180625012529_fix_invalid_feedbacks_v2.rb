class FixInvalidFeedbacksV2 < ActiveRecord::Migration[5.2]
  def up
    fixed_feedbacks = 0
    Feedback.where.not(legacy_feedback_type: nil).each do |feedback|
      normalized_feedback = case feedback.legacy_feedback_type.downcase
                            when /^true[a-z][-=].*/ then 'tpu-'
                            when /^true[a-z].*/ then 'tpu'
                            when /^true[-=].*/ then 'tp-'
                            when /^true.*/ then 'tp'
                            when /^false[a-z][-=].*/ then 'fpu-'
                            when /^false[a-z].*/ then 'fpu'
                            when /^false[-=].*/ then 'fp-'
                            when /^false.*/ then 'fp'
                            when /^tp[a-z][-=].*/ then 'tpu-'
                            when /^tp[a-z].*/ then 'tpu'
                            when /^fp[a-z][-=].*/ then 'tpu-'
                            when /^fp[a-z].*/ then 'tpu'
                            when /^naa[-=].*/ then 'naa-'
                            when /^naa.*/ then 'naa'
                            when /^n/ then 'naa-'
                            when /^f/ then 'fp-'
                            when /^k/ then 'tp-'
                            when /^ignore[-=]/ then 'ignore-'
                            when /^ignore/ then 'ignore'
                            else; 'invalid'
                            end
      puts "#{feedback.legacy_feedback_type}\t#{normalized_feedback}"
      if feedback.feedback_type != normalized_feedback
        # Skip validation
        feedback.update_columns(feedback_type: normalized_feedback)
        fixed_feedbacks += 1
      end
    end
    puts "Fixed #{fixed_feedbacks} feedbacks"
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
