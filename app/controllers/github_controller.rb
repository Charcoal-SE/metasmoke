class GithubController < ApplicationController
  skip_before_action :verify_authenticity_token

  def hook
    # Check signature from GitHub

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)
    puts "calculated signature: #{signature} | #{request.env['HTTP_X_HUB_SIGNATURE']}"

    render text: "You're not GitHub!", status: 403 and return unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])

    # If the signature is good, create a
    # new CommitStatus

    if CommitStatus.find_by_commit_sha_and_status(params[:sha], "success")
      render text: "Already recorded success for commit", status: 200
      return
    end

    if params[:state] == "pending"
      render text: "We don't record pending statuses", status: 200
      return
    end

    status = CommitStatus.new
    status.commit_sha = params[:sha]
    status.status = params[:state]
    status.commit_message = params[:commit][:commit][:message]
    status.ci_url = params[:target_url]
    status.save!

    render text: "OK", status: 200
  end
end
