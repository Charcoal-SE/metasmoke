# frozen_string_literal: true

class UpdateModeratorSitesJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find(user_id).update_moderator_sites
  end
end
