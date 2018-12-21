# frozen_string_literal: true

class Redis::Reason < Redis::Base::Set
  source_type :reasons
  target_name :posts
end
