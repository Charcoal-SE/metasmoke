# frozen_string_literal: true

class ValidateFlagConditionForUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    FlagCondition.validate_for_user(User.find(user_id), User.find(-1))
    # Do something later
  end
end
