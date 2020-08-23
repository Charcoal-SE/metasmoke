# frozen_string_literal: true

class DeveloperController < ApplicationController
  before_action :authenticate_user!, except: [:blank_page]
  before_action :verify_developer, except: %i[blank_page change_back verify_elevation]
  before_action :check_st_functional_or_forced, only: %i[st_insert_post st_insert_post_synchronous st_insert_post_range
                                                         st_basic_search_raw st_sync st_sync_async]
  before_action :check_impersonating, only: %i[change_back verify_elevation]

  def st_mark_functional
    Rails.logger.warn "Suffix tree extension marked functional by #{current_user.username}"
    SuffixTreeHelper.mark_functional
  end

  def st_mark_broken
    reason = if params.key?(:reason) && !params[:reason].empty?
               params[:reason]
             else
               'stupidity of its developers'
             end
    Rails.logger.warn "Suffix tree extension marked broken by #{current_user.username}. Reason: #{reason}"
    SuffixTreeHelper.mark_broken reason
  end

  def st_dump
    if AppConfig['suffix_tree']['inplace_create']
      render 'Impossible', status: 503
    elsif SuffixTreeHelper.functional? && !params.key?(:force)
      render 'In almost all cases, you should mark suffix tree extension broken before' \
             ' downloading a dump, and mark it functional afterwards.', status: 403
    else
      send_file AppConfig['suffix_tree']['path']
    end
  end

  def st_insert_post
    InsertPostToSuffixTreeJob.perform_later params[:post_id]
  end

  def st_insert_post_synchronous
    SuffixTreeHelper.insert_post params[:post_id]
  end

  def st_insert_post_range
    BatchInsertPostToSuffixTreeJob.perform_later((params[:start_id].to_i..params[:end_id].to_i))
  end

  def st_basic_search_raw
    @post_ids = SuffixTreeHelper.basic_search(params[:pattern], params[:mask])
  end

  def st_sync
    SuffixTreeHelper.sync!
  end

  def st_sync_async
    SuffixTreeHelper.sync_async
  end

  def update_sites
    SitesHelper.update_sites
    flash[:info] = 'Site cache updated, refer to MiniProfiler for execution details.'
    redirect_back(fallback_location: url_for(controller: :dashboard, action: :index))
  end

  def production_log
    @log = if params[:grep].present?
             unless params[:context].respond_to?(:to_i)
               flash[:warning] = "Coercion failure on params[:context]: Can't convert to an interger"
               redirect_to(root_path) && return
             end
             `tail -n 10000 log/production.log | grep -E '#{params[:grep].to_s.tr("'", '')}' -C '#{params[:context].to_i}' --color=never`
           else
             `tail -n 1000 log/production.log`
           end

    # Don't modify frozen strings
    @log.gsub(/\e\[([;\d]+)?m/, '') # Terminal color codes
    @log.gsub(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/, '') # IPs
    @log.gsub(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i, '') # Emails
  end

  def make_space_in_logs
    redis(logger: true).zrange('requests', 0, -1, with_scores: true).each do |val, score|
      new_expire = REDIS_LOG_EXPIRATION.to_i - (Time.now.to_i - score.to_i)
      keys = redis(logger: true).scan_each(match: "request/#{score}*").to_a
      redis(logger: true).multi do
        if new_expire <= 0
          keys.each { |k| redis(logger: true).del(k) }
          redis(logger: true).zrem 'requests', val
        else
          keys.each do |k|
            redis(logger: true).expire k, new_expire
          end
        end
      end
    end
  end

  def deploy
    message = "[ [metasmoke-deploy](//travis-ci.org/Undo1/metasmoke-deploy) ] deploy started by #{current_user.username}"
    SmokeDetector.send_message_to_charcoal(message)

    # old_message = Octokit.commit('Charcoal-SE/metasmoke', CurrentCommit)['commit']['message']
    old_sha = CurrentCommit.first(7)

    commit = Octokit.commits('Charcoal-SE/metasmoke')[0]
    message = commit['commit']['message']
    sha = commit['sha'].first(7)

    redis_log HTTParty.post('https://api.travis-ci.org/repo/19152912/requests', headers: {
                              'Content-Type' => 'application/json',
                              'Accept' => 'application/json',
                              'Travis-API-Version' => '3',
                              'Authorization' => "token #{AppConfig['travis']['token']}"
                            }, body: {
                              request: {
                                branch: 'master',
                                message: "#{old_sha} -> #{sha}: #{message}"
                              }
                            }.to_json)

    redirect_to 'https://travis-ci.org/Undo1/metasmoke-deploy'
  end

  def query_times_log
    send_file 'log/query_times.log'
  end

  def blank_page
    render layout: false
  end

  def empty_layout
    render layout: true
  end

  def websocket_test; end

  def send_websocket_test
    ActionCable.server.broadcast params[:channel], JSON.parse(params[:content])
    flash[:info] = 'Queued for broadcast.'
    redirect_to url_for(controller: :developer, action: :websocket_test)
  end

  def change_users
    dev_id = current_user.id
    @user = User.find params[:id]
    sign_in @user
    session[:impersonator_id] = dev_id
    flash[:success] = "You are now impersonating #{@user.username}."
    redirect_to root_path
  end

  def change_back
    @impersonator = User.find session[:impersonator_id]
  end

  def verify_elevation
    @impersonator = User.find session[:impersonator_id]
    if @impersonator&.valid_password? params[:password]
      session.delete :impersonator_id
      sign_in @impersonator
      redirect_to root_path
    else
      flash[:danger] = 'Incorrect password.'
      render :change_back
    end
  end

  def run_fcrs
    ConflictingFeedbackJob.perform_later
    flash[:success] = 'ConflictingFeedbackJob triggered.'
    redirect_back fallback_location: root_path
  end

  def run_feedback_reindex
    FeedbackReindexJob.perform_later
    flash[:success] = 'FeedbackReindexJob triggered.'
    redirect_back fallback_location: root_path
  end

  private

  def check_st_functional_or_forced
    return if SuffixTreeHelper.functional? || params.key?(:force)
    render "Suffix tree extension is broken due to #{SuffixTreeHelper.broken_reason}.", status: 500
  end

  def check_impersonating
    require_developer unless session[:impersonator_id].present?
  end
end
