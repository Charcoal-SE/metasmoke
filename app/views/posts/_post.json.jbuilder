json.merge! post.as_json
json.merge!(count_tp: post.feedbacks.to_a.count { |f| f.feedback_type.include? 't' },
            count_fp: post.feedbacks.to_a.count { |f| f.feedback_type.include? 'f' },
            count_naa: post.feedbacks.to_a.count { |f| f.feedback_type.include? 'n' },
            autoflagged: {
              flagged: post.flagged?,
              names: post.flag_logs.select { |f| f.success && f.is_auto }.map { |f| f.user.username },
              users: post.flaggers.map { |u| u.as_json.select { |k, _v| k == 'username' || k.include?('_chat_id') } }
            },
            manual_flags: {
              users: post.manual_flaggers.map { |u| u.as_json.select { |k, _v| k == 'username' || k.include?('_chat_id') } }
            },
            feedbacks: post.feedbacks.map { |f| { feedback_type: f.feedback_type, user_name: f.user_name || f.user.username } },
            reason_weight: post.reasons.map(&:weight).reduce(:+),
            revision_count: post.get_revision_count)
