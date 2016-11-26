class GithubController < ApplicationController
  skip_before_action :verify_authenticity_token

  def status_hook
    # We're not interested in PR statuses or branches other than master

    unless params[:branches].index { |b| b[:name] == "master" }
      render text: "Not a commit on master. Uninterested." and return
    end

    # Check signature from GitHub

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)
    puts "calculated signature: #{signature} | #{request.env['HTTP_X_HUB_SIGNATURE']}"

    render text: "You're not GitHub!", status: 403 and return unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])

    # If the signature is good, create a
    # new CommitStatus

    if CommitStatus.find_by_commit_sha(params[:sha])
      render text: "Already recorded status for commit", status: 200
      return
    end

    if params[:state] == "pending"
      render text: "We don't record pending statuses", status: 200
      return
    end

    commit_sha = params[:sha]
    status = params[:state]
    commit_message = params[:commit][:commit][:message]
    ci_url = params[:target_url]

    ActionCable.server.broadcast "smokedetector_messages", { commit_status: { status: status, ci_url: ci_url, commit_sha: commit_sha, commit_message: commit_message } }
    CommitStatus.create(:commit_sha => commit_sha, :status => status)

    render text: "OK", status: 200
  end

  def pull_request_hook
    # Check signature from GitHub

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)
    puts "calculated signature: #{signature} | #{request.env['HTTP_X_HUB_SIGNATURE']}"

    render text: "You're not GitHub!", status: 403 and return unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])

    unless request.request_parameters[:action] == "opened"
      render text: "Not a newly-opened PR. Uninterested." and return
    end

    pull_request = params[:pull_request]

    unless pull_request[:user][:login] == "SmokeDetector"
      render text: "Not from SmokeDetector. Uninterested." and return
    end

    text = pull_request[:body]

    domains = text.scan(/<!-- METASMOKE-BLACKLIST (.*?) -->/)[0][0].split("|")

    response_text = ""

    domains.each do |domain|
      # Run a search on each, find stats...

      num_tps = Post.where("body LIKE '%#{domain}%'").where(:is_tp => true).count
      num_fps = Post.where("body LIKE '%#{domain}%'").where(:is_fp => true).count

      response_text += "#{domain} has been seen in #{num_tps} true #{'positives'.pluralize(num_tps)} and #{num_fps} false #{'positives'.pluralize(num_fps)}.\n\n"
    end

    render text: response_text, status: 444
  end
end
