class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def hook
    render text: "OK", status: 200
  end
end
