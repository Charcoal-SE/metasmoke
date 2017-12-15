# frozen_string_literal: true

module API
  class ReasonsAPI < API::Base
    get '/' do
      std_result Reason.all.order(id: :desc), filter: FILTERS[:reasons]
    end

    get ':ids' do
      std_result Reason.where(id: params[:ids].split(',')).order(id: :desc), filter: FILTERS[:reasons]
    end

    get ':id/posts' do
      std_result Reason.find(params[:id]).posts.order(id: :desc), filter: FILTERS[:posts]
    end
  end
end
