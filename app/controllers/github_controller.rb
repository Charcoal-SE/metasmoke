# frozen_string_literal: true

require 'open-uri'
include APIHelper

class GithubController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_github, except: [:update_deploy_to_master, :add_pullapprove_comment]
  before_action :check_if_smokedetector, only: [:add_pullapprove_comment]

  cattr_accessor :git_mutex
  GithubController.git_mutex = Mutex.new

  # Fires whenever a CI service finishes.
  def status_hook
    # We're not interested in PR statuses or branches other than deploy
    unless params[:branches].index { |b| b[:name] == 'deploy' }
      render(text: 'Not a commit on deploy. Uninterested.') && return
    end

    # Create a new CommitStatus

    if CommitStatus.find_by(commit_sha: params[:sha])
      render text: 'Already recorded status for commit', status: 200
      return
    end

    if params[:state] == 'pending'
      render text: "We don't record pending statuses", status: 200
      return
    end

    commit_sha = params[:sha]
    status = params[:state]
    commit_message = params[:commit][:commit][:message]
    ci_url = params[:target_url]

    ActionCable.server.broadcast 'smokedetector_messages', commit_status: {
      status: status,
      ci_url: ci_url,
      commit_sha: commit_sha,
      commit_message: commit_message
    }
    CommitStatus.create(commit_sha: commit_sha, status: status)

    render text: 'OK', status: 200
  end

  # Fires when a wiki page is updated on Charcoal-SE/metasmoke or Charcoal-SE/SmokeDetector
  def gollum_hook
    Travis::Repository.find('Charcoal-SE/charcoal-se.github.io').last_build.restart
  end

  # Fires whenever a PR is opened to check for auto-blacklist and post stats
  def pull_request_hook
    unless request.request_parameters[:action] == 'opened'
      render(text: 'Not a newly-opened PR. Uninterested.') && return
    end

    pull_request = params[:pull_request]

    unless pull_request[:user][:login] == 'SmokeDetector'
      render(text: 'Not from SmokeDetector. Uninterested.') && return
    end

    text = pull_request[:body]

    response_text = ''

    # Identify blacklist type and use appropriate search

    domains = text.scan(/<!-- METASMOKE-BLACKLIST-WEBSITE (.*?) -->/)

    domains.each do |domain|
      domain = domain[0]
      domain.gsub! '\W', '[^A-Za-z0-9]'

      num_tps = Post.where('body REGEXP ?', "#{domain}").where(is_tp: true).count
      num_fps = Post.where('body REGEXP ?', "#{domain}").where(is_fp: true).count
      num_naa = Post.where('body REGEXP ?', "#{domain}").where(is_naa: true).count

      response_text += get_line domain, num_tps, num_fps, num_naa
    end

    keywords = text.scan(/<!-- METASMOKE-BLACKLIST-KEYWORD (.*?) -->/)

    keywords.each do |keyword|
      keyword = keyword[0]
      keyword.gsub! '\W', '[^A-Za-z0-9]'

      num_tps = Post.where('body REGEXP ?', "#{keyword}").where(is_tp: true).count
      num_fps = Post.where('body REGEXP ?', "#{keyword}").where(is_fp: true).count
      num_naa = Post.where('body REGEXP ?', "#{keyword}").where(is_naa: true).count

      response_text += get_line keyword, num_tps, num_fps, num_naa
    end

    usernames = text.scan(/<!-- METASMOKE-BLACKLIST-USERNAME (.*?) -->/)

    usernames.each do |username|
      username = username[0]
      username.gsub! '\W', '[^A-Za-z0-9]'

      num_tps = Post.where('username REGEXP ?', "#{username}").where(is_tp: true).count
      num_fps = Post.where('username REGEXP ?', "#{username}").where(is_fp: true).count
      num_naa = Post.where('username REGEXP ?', "#{username}").where(is_naa: true).count

      response_text += get_line username, num_tps, num_fps, num_naa
    end

    watches = text.scan(/<!-- METASMOKE-BLACKLIST-WATCH_KEYWORD (.*?) -->/)

    watches.each do |watch|
      watch = watch[0]
      watch.gsub! '\W', '[^A-Za-z0-9]'

      num_tps = Post.where('body REGEXP ?', "#{watch}").where(is_tp: true).count
      num_fps = Post.where('body REGEXP ?', "#{watch}").where(is_fp: true).count
      num_naa = Post.where('body REGEXP ?', "#{watch}").where(is_naa: true).count

      response_text += get_line watch, num_tps, num_fps, num_naa
    end

    Octokit.add_comment 'Charcoal-SE/SmokeDetector', pull_request[:number], response_text

    render text: response_text, status: 200
  end

  def get_line(thing, num_tps, num_fps, num_naa)
    response_text  = "`#{thing}` has been seen in #{num_tps} true #{'positive'.pluralize(num_tps)}"
    response_text += ", #{num_fps} false #{'positive'.pluralize(num_fps)}"
    response_text += ", and #{num_naa} #{'NAA'.pluralize(num_naa)}."
    response_text + "\n\n"
  end

  # Fires when a PR is posted for our fake CI service to require reviews on
  def ci_hook
    case request.headers['HTTP_X_GITHUB_EVENT']
    when 'pull_request'
      data = JSON.parse(request.raw_post)
      pull_request = data['pull_request']
      case data['action']
      when 'opened', 'synchronize'
        commits = JSON.parse(Net::HTTP.get_response(URI.parse(pull_request['commits_url'])).body)
        commits.each do |commit|
          APIHelper.authorized_post(
            "https://api.github.com/repos/Charcoal-SE/SmokeDetector/statuses/#{commit['sha']}",
            state: 'pending',
            description: 'An Approve review is required before pull requests can be merged.',
            context: 'metasmoke/ci'
          )
        end
        render plain: "#{commits.length} commits set to pending."
      else
        render(plain: 'Not a newly-opened or updated PR; not interested.') && return
      end
    when 'pull_request_review'
      data = JSON.parse(request.raw_post)
      pull_request = data['pull_request']
      review = data['review']
      if data['action'] == 'submitted' && review['state'] == 'approved'
        commits = JSON.parse(Net::HTTP.get_response(URI.parse(pull_request['commits_url'])).body)
        commits.each do |commit|
          APIHelper.authorized_post(
            "https://api.github.com/repos/Charcoal-SE/SmokeDetector/statuses/#{commit['sha']}",
            state: 'success',
            description: 'PR approved :)',
            context: 'metasmoke/ci'
          )
        end

        render plain: "#{commits.length} commits approved."
      else
        render(plain: 'Not a submitted Approve review; not interested.') && return
      end
    else
      render(plain: "Pretty sure we don't subscribe to that event.") && return
    end
  end

  # Fires when a new push is made to Charcoal-SE/metasmoke, so we can bust
  # the status/code caches
  def metasmoke_push_hook
    Rails.cache.delete_matched %r{code_status/.*##{CurrentCommit}}
  end

  # Fires whenever anything is pushed, so we can automatically update `deploy`
  # to point to master's HEAD
  def update_deploy_to_master
    unless params[:ref] == 'refs/heads/master'
      render(plain: 'Not on master; not interested') && return
    end

    new_sha1 = params[:after]

    # false indicates a not-force-push
    Octokit.update_ref 'Charcoal-SE/SmokeDetector', 'heads/deploy', new_sha1, false

    # See https://developer.github.com/v3/activity/events/types/#webhook-payload-example-26
    # for what’s in `params`
    ActionCable.server.broadcast 'smokedetector_messages', deploy_updated: params
    ApiChannel.broadcast_to 'ref_update', event_type: 'update', event_class: 'Ref', object: params
  end

  def any_status_hook
    repo = params[:name]
    link = "https://github.com/#{repo}"
    sha = params[:sha]
    state = params[:state]
    context = params[:context]
    description = params[:description]
    target = params[:target_url]

    return if state == 'pending' || (state == 'success' && context == 'github/pages')

    message = "[ [#{repo.sub('Charcoal-SE/', '')}](#{link}) ]"
    message += " #{context} "
    message += if target.present?
                 "[#{state}](#{target})"
               else
                 state
               end
    message += " on [#{sha.first(7)}](#{link}/commit/#{sha.first(10)})"
    message += ": #{description}" if description.present?

    ActionCable.server.broadcast 'smokedetector_messages', message: message
  end

  def pullapprove_merge_hook
    context = params[:context]
    state = params[:state]
    target = params[:target_url]

    if context == 'code-review/pullapprove' && state == 'success'
      pr_num = %r{https?:\/\/pullapprove\.com\/Charcoal-SE\/SmokeDetector\/pull-request\/(\d+)\/?}.match(target)[1].to_i
      pr = Octokit.client.pull_request('Charcoal-SE/SmokeDetector', pr_num)

      if pr[:user][:login] != 'SmokeDetector'
        render plain: "Not a blacklist PR, not merging (##{pr_num})"
        return
      end

      unless Dir.exist?('SmokeDetector')
        system 'git clone git@github.com:Charcoal-SE/SmokeDetector'

        Dir.chdir('SmokeDetector') do
          system 'git config user.name metasmoke'
          system 'git', 'config', 'user.email', AppConfig['github']['username']

          File.write '.git/info/attributes', <<~END
            bad_keywords.txt -text merge=union
            blacklisted_usernames.txt -text merge=union
            blacklisted_websites.txt -text merge=union
            watched_keywords.txt -text merge=union
          END
        end
      end

      if !Octokit.client.pull_merged?('Charcoal-SE/SmokeDetector', pr_num)
        GithubController.git_mutex.synchronize do
          Dir.chdir('SmokeDetector') do
            ref = pr[:head][:ref]

            system 'git fetch origin master; git checkout -B master origin/master'
            system 'git', 'fetch', 'origin', ref
            system 'git', 'merge', "origin/#{ref}", '--no-ff', '-m', "Merge pull request ##{pr_num} from Charcoal-SE/#{ref} --autopull"
            system 'git push origin master'
            system 'git', 'push', 'origin', '--delete', ref
            system 'git', 'branch', '-D', ref
          end
        end

        message = "Merged SmokeDetector [##{pr_num}](https://github.com/Charcoal-SE/SmokeDetector/pull/#{pr_num})."
        ActionCable.server.broadcast('smokedetector_messages', message: message)
        render plain: "Merged ##{pr_num}"
      else
        render plain: "##{pr_num} already merged"
      end
    else
      render plain: 'Not PullApprove successful status, ignoring'
    end
  end

  def add_pullapprove_comment
    pr_num = params[:number]
    Octokit.client.add_comment 'Charcoal-SE/SmokeDetector', pr_num, '!!/approve'
    render plain: 'OK'
  end

  private

  def verify_github
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)
    render(plain: "You're not GitHub!", status: 403) && return unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end
end
