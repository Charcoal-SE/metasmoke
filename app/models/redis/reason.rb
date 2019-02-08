# frozen_string_literal: true

class Redis::Reason < Redis::Base::Set
  source_type :reasons
  target_name :posts

  def update_reason_feedback_cache(feedback_type)
    feedback_type = "#{feedback_type}s" unless feedback_type.to_s.last == 's'
    redis.multi do
      intersect(feedback_type).store("#{prefix}/#{id}/#{feedback_type}")
      # Why is this reasons/prefix/<fb> rather than <fbs>
      for_feedback(feedback_type).difference('fps', 'naas').update! if feedback_type == 'tps'
      for_feedback(feedback_type).difference('tps', 'naas').update! if feedback_type == 'fps'
    end
  end

  def clear_reason_feedback_cache(feedback_type)
    feedback_type = "#{feedback_type}s" unless feedback_type.to_s.last == 's'
    redis.del "#{prefix}/#{id}/#{feedback_type}"
  end

  def for_feedback(feedback_type)
    Redis::Base::Collection.new("#{prefix}/#{id}/#{feedback_type}", type: :set)
  end
end
