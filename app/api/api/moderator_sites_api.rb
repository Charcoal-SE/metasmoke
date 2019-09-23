# frozen_string_literal: true

module API
  class ModeratorSitesAPI < API::BaseWithoutAuth
    # Deliberately not authenticated

    get '/' do
      std_result ModeratorSite.all, filter: FILTERS[:mods]
    end

    get 'user/:id' do
      std_result ModeratorSite.where(user_id: params[:id]), filter: FILTERS[:mods]
    end
  end
end
