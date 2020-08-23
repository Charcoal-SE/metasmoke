# frozen_string_literal: true

class ValidateFlagConditionForUserJob < ApplicationJob
  queue_as :default

  def perform(user_id, other_user_id = -1)
    FlagCondition.validate_for_user(User.find(user_id), User.find(other_user_id))
    # Do something later
  end
end
