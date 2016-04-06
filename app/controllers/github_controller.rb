class GithubController < ApplicationController
  skip_before_action :verify_authenticity_token

  def hook
    render text: "OK", status: 200
  end
end
