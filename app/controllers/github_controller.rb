# frozen_string_literal: true

require 'open-uri'

class GithubController < ApplicationController
  include APIHelper

  skip_before_action :redis_log_request
  skip_before_action :verify_authenticity_token
  before_action :verify_github, except: %i[update_deploy_to_master add_pullapprove_comment]
  before_action :check_if_smokedetector, only: [:add_pullapprove_comment]

  # The goal with most of these routes is to respond to things happening on the various GitHub repositories.
  # Each repository is set up with one or more WebHooks to the functions defined here.
  # Most of these recognize some specific thing happening in the repository and send a message to SmokeDetector,
  # which is then forwarded to SE chat.
  #
  # From a conceptual standpoint, the things we're looking to detect are:
  #  CI testing failures, and what failed
  #  CI testing success, if everything passed, but not success of individual sub-portions.
  #  Changes to either metasmoke's wiki or SmokeDetector's wiki, in order to start a new build of the Charcoal site.
  #  Creation of PRs
  #  Pushes to SmokeDetector's master branch, so we can update the deploy branch
  #  Pushes to metasmoke's master branch to update the developer info cache
  #
  # CI testing
  #   Unfortunately, keeping track of what's happening with CI testing is a bit complicated. To a significant
  #   extent, this is because there are multiple WebHooks which are fired, depending on the type of CI testing.
  #   "Statuses" WebHooks: CI testing performed by an external service (e.g. CircleCI and Travis CI).
  #     What is reported is entirely dependent on what is provided to GitHub from the external service through
  #     the GitHub API. Generally, this is status messages indicating starting and completing the testing.
  #     At least CircleCI updates status for each separate run within the suite of tests defined to be run.
  #     There are individual events which separately indicate failure, but overall success is indicated only by
  #     all expected runs resulting in "success".
  #   "Check suites" WebHooks: Fired upon completion of a suite of GitHub Actions. Indicates overall success/failure,
  #     but doesn't appear to indicate what failed. A PR is only indicated in the WebHook when the PR is created.
  #   "Check runs" WebHooks: Fired for each sub-task within a set of GitHub Actions, with an event when each run is
  #     "created" and/or "completed". The ones fired for "completed" indicate success or failure for each run.
  #     If a matrix of testing is defined, then each value in the matrix is considered a separate "run".
  #     A PR is only indicated in the WebHook when the PR is created.
  #
  #   GitHub Actions
  #     Failure of each separate run can be recognized and reported based on "failures" seen in "Check runs" WebHooks.
  #     Success of the overall suite can be recognized and reported based on "success" seen in "Check suites" WebHooks.
  #     If a push is done at the same time as a PR is created (e.g. editing a file on GitHub from which a PR is
  #       created), then two Check suites are created and run, or, at least, double the number of "Check runs" are
  #       created and executed, but we're only going to want to report success or failure once within a short time
  #       on a single commit.
  #
  #   CircleCI
  #     Failure of each separate run can be recognized and reported based on "failures" seen in "Statuses" WebHooks.
  #     Success of the overall suite can only be determined by seeing "success" in the status for all runs which
  #       are expected for a particular commit. There is no information provided as to the total number of runs
  #       which should be created per CI, so that's something we need to know a priori.
  #
  # Notes:
  #   GitHub sends an "action" parameter in some WebHooks. Its value is unavailable, due to "action" being a reserved
  #     parameter.

  # This is invoked by the route: /github/status_hook
  # GitHub fires the status WebHook when there's a status update reported to GitHub via the GitHub API.
  # It fires when an external CI service updates status (e.g. starts/finishes).
  # It is not fired for GitHub Actions. GitHub does fire this WebHook for GitHub Pages builds.
  # It is set up for the SmokeDetector repository to receive status changes.
  def status_hook
    # We're not interested in PR statuses or branches other than deploy
    render(text: 'Not a commit on deploy. Uninterested.') && return unless params[:branches].index do |b|
                                                                             b[:name] == 'deploy'
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
    # This only fires when we want to update the charcoal-se.org website, so we just unconditionally
    #   kick off a build of the charcoal-se.org website.
    APIHelper.authorized_post(
      'https://api.github.com/repos/Charcoal-SE/charcoal-se.github.io/actions/workflows/build.yml/dispatches',
      data: { 'ref' => 'site' }
    )
  end

  # Fires whenever a PR is opened on the SmokeDetetor repository to check for auto-blacklist and post stats
  def pull_request_hook
    render(text: 'Not a newly-opened PR. Uninterested.') && return unless request.request_parameters[:action] == 'opened'

    pull_request = params[:pull_request]

    SmokeDetector.send_message_to_charcoal("[PR##{pull_request[:number]}]"\
                                           "(https://github.com/Charcoal-SE/SmokeDetector/pull/#{pull_request[:number]})"\
                                           " (\"#{pull_request[:title]}\") opened by #{pull_request[:user][:login]}")

    render(text: 'Not from SmokeDetector. Uninterested.') && return unless pull_request[:user][:login] == 'SmokeDetector'

    text = pull_request[:body]

    response_text = ''

    # Identify blacklist type and use appropriate search

    domains = text.scan(/<!-- METASMOKE-BLACKLIST-WEBSITE (.*?) -->/)

    domains.each do |domain|
      domain = domain[0]

      num_tps = Post.where('body REGEXP ?', domain).where(is_tp: true).count
      num_fps = Post.where('body REGEXP ?', domain).where(is_fp: true).count
      num_naa = Post.where('body REGEXP ?', domain).where(is_naa: true).count

      response_text += get_line domain, num_tps, num_fps, num_naa
    end

    keywords = text.scan(/<!-- METASMOKE-BLACKLIST-KEYWORD (.*?) -->/)

    keywords.each do |keyword|
      keyword = keyword[0]

      num_tps = Post.where('body REGEXP ?', keyword).where(is_tp: true).count
      num_fps = Post.where('body REGEXP ?', keyword).where(is_fp: true).count
      num_naa = Post.where('body REGEXP ?', keyword).where(is_naa: true).count

      response_text += get_line keyword, num_tps, num_fps, num_naa
    end

    usernames = text.scan(/<!-- METASMOKE-BLACKLIST-USERNAME (.*?) -->/)

    usernames.each do |username|
      username = username[0]

      num_tps = Post.where('username REGEXP ?', username).where(is_tp: true).count
      num_fps = Post.where('username REGEXP ?', username).where(is_fp: true).count
      num_naa = Post.where('username REGEXP ?', username).where(is_naa: true).count

      response_text += get_line username, num_tps, num_fps, num_naa
    end

    watches = text.scan(/<!-- METASMOKE-BLACKLIST-WATCH_KEYWORD (.*?) -->/)

    watches.each do |watch|
      watch = watch[0]

      num_tps = Post.where('body REGEXP ?', watch).where(is_tp: true).count
      num_fps = Post.where('body REGEXP ?', watch).where(is_fp: true).count
      num_naa = Post.where('body REGEXP ?', watch).where(is_naa: true).count

      response_text += get_line watch, num_tps, num_fps, num_naa
    end

    Octokit.add_comment 'Charcoal-SE/SmokeDetector', pull_request[:number], response_text

    render text: response_text, status: 200
  end

  def get_line(thing, num_tps, num_fps, num_naa)
    response_text  = "`#{thing}` has been seen in #{num_tps} true #{'positive'.pluralize(num_tps)}"
    response_text += ", #{num_fps} false #{'positive'.pluralize(num_fps)}"
    response_text += ", and #{num_naa} #{'NAA'.pluralize(num_naa)}."
    "#{response_text}\n\n"
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

      unless data['action'] == 'submitted' && review['state'] == 'approved'
        render plain: 'Not a submitted Approve review; not interested.'
        return
      end

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
    render(plain: 'Not on master; not interested') && return unless params[:ref] == 'refs/heads/master'

    new_sha1 = params[:after]

    # false indicates a not-force-push
    Octokit.update_ref 'Charcoal-SE/SmokeDetector', 'heads/deploy', new_sha1, false

    # See https://developer.github.com/v3/activity/events/types/#webhook-payload-example-26
    # for what’s in `params`
    ActionCable.server.broadcast 'smokedetector_messages', deploy_updated: params
    ApiChannel.broadcast_to 'ref_update', event_type: 'update', event_class: 'Ref', object: params
  end

  # This is invoked by the route: /github/report_check_suite_success
  # It's intended to be triggered by GitHub Check Suites WebHooks in order to have SD report success of the full
  #   suite of GitHub Actions in chat. The hook is also fired by GitHub for failure, but we ignore those, as it's
  #   assumed those are being reported by the check_runs WebHook, due to check_suite event not having information
  #   as to which runs within a suite failed.
  # "check_suite" events are not triggered by external CI providers (e.g. CircleCI and Travis CI).
  # A check_suite event is fired for each set of CI testing which is run through GitHub Actions.
  # One "completed" event is sent for each GitHub Action complete set which is executed.
  # This route only reports successes and ignores suites started for SmokeDetector.
  # Concerns:
  #   When a PR is created directly from a branch at the same time as the branch, we can get called for two
  #   concurrent runs, which both show as associated with the PR, but we only want to report one for the commit.
  #   In that situation, we get two "completed" messages. This is resolved by using a Redis success counter to
  #   track how many we get and only forwarding the first one within 20 minutes to SmokeDetector.
  def report_check_suite_success
    data = params
    check_suite = data[:check_suite]
    conclusion = check_suite[:conclusion]
    branch = check_suite[:head_branch]
    pull_requests = check_suite[:pull_requests]
    pull_request = pull_requests[0]
    sha = check_suite[:head_sha]
    check_suite_status = check_suite[:status]
    repository = data[:repository]
    repo_name = repository[:name]
    repo_url = repository[:html_url]
    app_name = check_suite[:app][:name]
    sender_login = data[:sender][:login]
    pr_number = pull_request[:number] if pull_request.present?
    branch_path = ''
    branch_path = "/tree/#{branch}" if branch != 'master'

    # We are only interested in completed successes
    return if check_suite_status != 'completed' || conclusion != 'success' || sender_login == 'SmokeDetector'

    message = "[ [#{repo_name}](#{repo_url}) ]"
    message += " #{app_name}:"
    message += if pull_request.present?
                 " [#{conclusion}](#{repo_url}/pull/#{pr_number}/checks?sha=#{sha})"
               else
                 " [#{conclusion}](#{repo_url}/commit/#{sha}/checks)"
               end
    message += " on [#{sha.first(7)}](#{repo_url}/commit/#{sha.first(10)})"
    message += " by #{sender_login}" if sender_login.present?
    message += " in the [#{branch}](#{repo_url}#{branch_path}) branch" if branch.present?
    message += " for [PR ##{pr_number}](#{repo_url}/pull/#{pr_number})" if pull_request.present?

    # We don't want to send more than one message for this SHA with the same conclusion within 20 minutes.
    # This counter expires from Redis in 20 minutes.
    ci_counter = Redis::CI.new("check_suite_#{conclusion}_#{sha}")
    ci_counter.sucess_count_incr
    ActionCable.server.broadcast 'smokedetector_messages', message: message if ci_counter.sucess_count == 1
  end

  # This is invoked by the route: /github/report_check_run_failure
  # It's triggered by GitHub Action check runs in order to provide status to SmokeDetector to forward to chat.
  # Any conclusion other than "success" is forwarded to chat for the master branch or any PR.
  # It is not triggered by external CI providers (e.g. CircleCI and Travis CI).
  # A check_run event happens for each check that's run as part of CI testing. This is two events,
  #   one "created" and one "completed" for each GitHub Action workflow/matrix which is executed.
  # The check_suite event hook might be better, for some use cases, as it will have only one event for all the
  #   checks which are dispatched for a particular situation. Unfortunately, that event doesn't have some of the
  #   data which it is desirable to show to the users in chat.
  # Concerns:
  #   When a PR is created directly from a branch at the same time as the branch, we can get called for two
  #     concurrent runs, but we only want to report one. In the case that's of interest, we get two "created"
  #     messages and then two "completed" messages. This is resolved by using a Redis success counter to track that
  #     we don't send more than one message about the same commit SHA with the same result/conclusion within 20 minutes.
  def report_check_run_failure
    data = params
    check_run = data[:check_run]
    check_run_status = check_run[:status]
    sha = check_run[:head_sha]
    workflow_name = check_run[:name]
    conclusion = check_run[:conclusion]
    check_run_url = check_run[:html_url]
    check_suite = check_run[:check_suite]
    app_name = check_run[:app][:name]
    details_url = check_run[:details_url]
    pull_requests = check_suite[:pull_requests]
    pull_request = pull_requests[0]
    branch = check_suite[:head_branch]
    repository = data[:repository]
    repo_name = repository[:name]
    repo_url = repository[:html_url]
    sender_login = data[:sender][:login]
    pr_number = pull_request[:number] if pull_request.present?
    branch_path = ''
    branch_path = "/tree/#{branch}" if branch != 'master'

    # We are only interested in completed non-success
    return if check_run_status != 'completed' || conclusion == 'success'

    message = "[ [#{repo_name}](#{repo_url}) ]"
    message += if app_name == 'GitHub Actions'
                 " GitHub Action workflow [#{workflow_name}](#{check_run_url}):"
               else
                 " Check run [#{workflow_name}](#{check_run_url}):"
               end
    message += if pull_request.present?
                 " [#{conclusion}](#{repo_url}/pull/#{pr_number}/checks?sha=#{sha})"
               else
                 " [#{conclusion}](#{details_url})"
               end
    message += " on [#{sha.first(7)}](#{repo_url}/commit/#{sha.first(10)})"
    message += " by #{sender_login}" if sender_login.present?
    message += " in the [#{branch}](#{repo_url}#{branch_path}) branch" if branch.present?
    message += " for [PR ##{pr_number}](#{repo_url}/pull/#{pr_number})" if pull_request.present?

    # We don't want to send more than one message for this workflow & sha with the same conclusion within 20 minutes.
    # This counter expires from Redis in 20 minutes.
    ci_counter = Redis::CI.new("check_run_#{workflow_name}_#{conclusion}_#{sha}")
    ci_counter.sucess_count_incr
    ActionCable.server.broadcast 'smokedetector_messages', message: message if ci_counter.sucess_count == 1
  end

  # This is invoked by the route: /github/project_status
  # GitHub fires the status WebHook when there's a status update reported to GitHub via the GitHub API.
  # It fires when an external CI service updates status (e.g. finishes).
  # It is not fired for GitHub Actions. GitHub does fire this WebHook for GitHub Pages builds.
  # It's used to pass repository status changes to SmokeDetector for display in SE chat.
  # For the metasmoke repository:
  #   In order for success to be reported for 'ci/circleci' contexts, then this endpoint needs to be
  #   called three times within 20 minutes with the same SHA and 'success'. This is done because the
  #   metasmoke repository has three jobs run on CircleCI for each CI run and we only want to report
  #   success when all of them pass.
  #   States other than success will be reported with only one call to this endpoint.
  def any_status_hook
    repo = params[:name]
    link = "https://github.com/#{repo}"
    sha = params[:sha]
    state = params[:state]
    context = params[:context]
    description = params[:description]
    target = params[:target_url]

    return if state == 'pending' || (state == 'success' && context == 'github/pages')

    if repo == 'Charcoal-SE/metasmoke' && context.start_with?('ci/circleci')
      ci_counter = Redis::CI.new(sha)
      if state == 'success'
        ci_counter.sucess_count_incr
        return unless ci_counter.sucess_count == 3

        context = 'ci/circleci'
      else
        ci_counter.sucess_count_reset
      end
    end

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

  # This is invoked from /github/pr_merge.
  def pullapprove_merge_hook
    context = params[:context]
    state = params[:state]
    target = params[:target_url]

    if context == 'code-review/pullapprove' && state == 'success'
      pr_num = %r{https?://pullapprove\.com/Charcoal-SE/SmokeDetector/pull-request/(\d+)/?}.match(target)[1].to_i
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
        end
      end

      if Octokit.client.pull_merged?('Charcoal-SE/SmokeDetector', pr_num)
        render plain: "##{pr_num} already merged"
      else
        File.open('SmokeDetector/.git/info/attributes', File::RDWR) do |f|
          f.flock(File::LOCK_EX)

          Dir.chdir('SmokeDetector') do
            ref = pr[:head][:ref]

            system 'git fetch origin master; git checkout -B master origin/master'
            system 'git', 'fetch', 'origin', ref
            system 'git', 'merge', "origin/#{ref}", '--no-ff', '-m',
                   "Merge pull request ##{pr_num} from Charcoal-SE/#{ref} --autopull"
            system 'git push origin master'
            system 'git', 'push', 'origin', '--delete', ref
            system 'git', 'branch', '-D', ref
          end
        end

        message = "Merged SmokeDetector [##{pr_num}](https://github.com/Charcoal-SE/SmokeDetector/pull/#{pr_num})."
        ActionCable.server.broadcast('smokedetector_messages', message: message)
        render plain: "Merged ##{pr_num}"
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
    signature = "sha1=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), AppConfig['github']['secret_token'], request.raw_post)}"
    render(plain: "You're not GitHub!", status: 403) unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end
end
