class AdminController < ApplicationController
  before_filter :verify_admin

  def index
  end

  private
    def verify_admin
      if !user_signed_in? || !current_user.is_admin
        raise ActionController::RoutingError.new('Not Found') and return
      end
    end
end
