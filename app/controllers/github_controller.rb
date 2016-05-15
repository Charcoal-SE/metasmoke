class GithubController < ApplicationController
  skip_before_action :verify_authenticity_token

  def hook
    status = CommitStatus.new
    status.commit_sha = params[:sha]
    status.status = params[:state]
    status.commit_message = params['commit']['message']
    status.save!

    render text: "OK", status: 200
  end
end
