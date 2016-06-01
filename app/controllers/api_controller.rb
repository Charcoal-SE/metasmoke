class ApiController < ApplicationController
  before_action :verify_key

  private
    def verify_key
      unless params[:key].present? && ApiKey.where(:key => params[:key]).count == 1
        render :json => { :error_name => "unauthenticated", :error_code => 403, :error_message => "No key was passed or the passed key is invalid." }
      end
    end
end
