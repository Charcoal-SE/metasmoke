# frozen_string_literal: true

class FixInvalidFeedbacks < ActiveRecord::Migration[5.2]
  def change
    add_column :feedbacks, :legacy_feedback_type, :string

    reversible do |dir|
      dir.up do
        Feedback.where.not(feedback_type: Feedback::VALID_TYPES).each do |feedback|
          original_feedback = feedback.feedback_type
          normalized_feedback = case feedback.feedback_type.downcase
                                when /true[a-z][-=].*/ then 'tpu-'
                                when /true[a-z].*/ then 'tpu'
                                when /true[-=].*/ then 'tp-'
                                when /true.*/ then 'tp'
                                when /false[a-z][-=].*/ then 'fpu-'
                                when /false[a-z].*/ then 'fpu'
                                when /false[-=].*/ then 'fp-'
                                when /false.*/ then 'fp'
                                when /tp[a-z][-=].*/ then 'tpu-'
                                when /tp[a-z].*/ then 'tpu'
                                when /fp[a-z][-=].*/ then 'tpu-'
                                when /fp[a-z].*/ then 'tpu'
                                when /naa[-=].*/ then 'naa-'
                                when /naa.*/ then 'naa'
                                when /n/ then 'naa-'
                                when /f/ then 'fp-'
                                when /k/ then 'tp-'
                                else; 'invalid'
                                end
          puts "#{original_feedback}\t#{normalized_feedback}"
          # Skip validation
          feedback.update_columns(feedback_type: normalized_feedback, legacy_feedback_type: original_feedback)
          puts "Fixed #{Feedback.where.not(legacy_feedback_type: nil).count} feedbacks"
        end
      end
      dir.down do
        Feedback.where.not(legacy_feedback_type: nil).each do |feedback|
          feedback.update(feedback_type: feedback.legacy_feedbacks, legacy_feedback_type: nil)
        end
      end
    end
  end
end
