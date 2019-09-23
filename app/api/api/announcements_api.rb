# frozen_string_literal: true

module API
  class AnnouncementsAPI < API::BaseWithAuth
    get '/' do
      std_result Announcement.all.order(id: :desc), filter: FILTERS[:announcements]
    end

    get 'active' do
      std_result Announcement.where('expiry > ?', DateTime.now).order(id: :desc), filter: FILTERS[:announcements]
    end

    get 'expired' do
      std_result Announcement.where('expiry < ?', DateTime.now).order(id: :desc), filter: FILTERS[:announcements]
    end

    before do
      authenticate_user!
      role :core
    end
    params do
      requires :key, type: String
      requires :token, type: String
      requires :text, type: String
      requires :expiry, type: DateTime
    end
    post 'create' do
      announcement = Announcement.create(text: params[:text], expiry: params[:expiry])
      single_result announcement
    end
  end
end
