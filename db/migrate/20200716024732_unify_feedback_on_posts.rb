class UnifyFeedbackOnPosts < ActiveRecord::Migration[5.2]
  def change
    Feedback.where(feedback_type: 'ignore-_shouty_case').update(feedback_type: 'ignore')
    Feedback.where(feedback_type: 'trueu-').update(feedback_type: 'tpu-')
    Feedback.where(feedback_type: 'trueu').update(feedback_type: 'tpu')
    Feedback.where(feedback_type: 'false').update(feedback_type: 'fp')
    Feedback.where(feedback_type: 'naa2').update(feedback_type: 'naa')
    Feedback.where(feedback_type: 'true').update(feedback_type: 'tp')
    Feedback.where(feedback_type: 'Mith_now_youve_made_everyone_do_it').update(feedback_type: 'invalid')
    Feedback.where(feedback_type: 'This feature is brought to you').update(feedback_type: 'invalid')
    Feedback.where(feedback_type: 'This is Smokey. I've come to say goodbye, as I've been permanently broken').update(feedback_type: 'invalid')
  end
end
