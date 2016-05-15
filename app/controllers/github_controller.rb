class GithubController < ApplicationController
  skip_before_action :verify_authenticity_token

  def hook
    # Check signature from GitHub

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)
    puts "calculated signature: #{signature} | #{request.env['HTTP_X_HUB_SIGNATURE']}"

    render text: "You're not GitHub!", status: 403 and return unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])

    # If the signature is good, create a
    # new CommitStatus

    status = CommitStatus.new
    status.commit_sha = params[:sha]
    status.status = params[:state]
    status.commit_message = params[:commit][:commit][:message]
    status.save!

    render text: "OK", status: 200
  end
end
