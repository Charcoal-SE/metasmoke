require 'open-uri'

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
      num_naa = Post.where("body LIKE '%#{domain}%'").where(:is_naa => true).count

      response_text += "#{domain} has been seen in #{num_tps} true #{'positive'.pluralize(num_tps)}, #{num_fps} false #{'positive'.pluralize(num_fps)}, and #{num_naa} #{'NAA'.pluralize(num_naa)}.\n\n"
    end

    Octokit.add_comment "Charcoal-SE/SmokeDetector", pull_request[:number], response_text

    render text: response_text, status: 200
  end

  def ci_hook
    byebug
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)
    puts "calculated signature: #{signature} | #{request.env['HTTP_X_HUB_SIGNATURE']}"
    render plain: "You're not GitHub!", status: 403 and return unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])

    case request.headers['HTTP_X_GITHUB_EVENT']
      when 'pull_request'
        data = JSON.parse(request.raw_post)
        pull_request = data['pull_request']
        case data['action']
          when 'opened'
            commits = JSON.parse(Net::HTTP.get_response(URI.parse(pull_request['commits_url'])).body)
            PullRequest.create!(:has_review => false, :last_commit_sha => commits[-1]['sha'], :number => pull_request['number'])

            authorized_post("https://api.github.com/repos/Charcoal-SE/SmokeDetector/statuses/#{commits[-1]['sha']}", {
              :state => "pending",
              :description => "An Approve review is required before pull requests can be merged.",
              :context => "metasmoke/ci"
            })

            render plain: "Created PR record."
          when 'synchronize'
            commits = JSON.parse(Net::HTTP.get_response(URI.parse(pull_request['commits_url'])).body)
            PullRequest.find_by_number(pull_request['number']).update!(:last_commit_sha => commits[-1]['sha'])

            authorized_post("https://api.github.com/repos/Charcoal-SE/SmokeDetector/statuses/#{commits[-1]['sha']}", {
                :state => "pending",
                :description => "An Approve review is required before pull requests can be merged.",
                :context => "metasmoke/ci"
            })

            render plain: "Updated final commit SHA."
          else
            render plain: "Not a newly-opened or updated PR; not interested." and return
        end
      when 'pull_request_review'
        data = JSON.parse(request.raw_post)
        pull_request = data['pull_request']
        review = data['review']
        if data['action'] == 'submitted' && review['state'] == 'approved'
          PullRequest.find_by_number(pull_request['number']).update!(:has_review => true)
          commits = JSON.parse(Net::HTTP.get_response(URI.parse(pull_request['commits_url'])).body)
          commits.each do |commit|
            authorized_post("https://api.github.com/repos/Charcoal-SE/SmokeDetector/statuses/#{commit['sha']}", {
                :state => "success",
                :description => "PR approved :)",
                :context => "metasmoke/ci"
            })
          end

          render plain: "#{commits.length} commits approved."
        else
          render plain: "Not a submitted Approve review; not interested." and return
        end
      else
        render plain: "Pretty sure we don't subscribe to that event." and return
    end
  end

  private
  def authorized_post(uri, data)
    private_pem = File.read("#{Rails.root}#{AppConfig['github']['integration_pem_file']}")
    private_key = OpenSSL::PKey::RSA.new(private_pem)
    payload = {
      iat: Time.now,
      exp: 1.minute.from_now.to_i,
      iss: AppConfig['github']['integration_id']
    }
    jwt = JWT.encode(payload, private_key, "RS256")

    resp = HTTParty.post(uri, :body => data.to_json, :headers => {
      'Content-Type' => 'application/json',
      'Accept' => 'application/vnd.github.machine-man-preview+json',
      'Authorization' => "Bearer #{jwt}",
      'User-Agent' => 'metasmoke-ci/1.0'
    })

    JSON.parse(resp.body)
  end
end
