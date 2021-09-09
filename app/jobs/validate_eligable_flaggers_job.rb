# frozen_string_literal: true

class ValidateEligableFlaggersJob < ApplicationJob
  queue_as :default

  def perform(post)
    sys = User.find(-1)
    post.eligible_flaggers.each do |u|
      FlagCondition.validate_for_user(u, sys)
    end
  end
end
