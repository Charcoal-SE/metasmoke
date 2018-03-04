# frozen_string_literal: true

class StackExchangeUsersController < ApplicationController
  before_action :authenticate_user!, only: [:update_data]
  before_action :verify_at_least_one_diamond, only: [:dead]
  before_action :set_stack_exchange_user, only: [:show]

  def index
    @users = StackExchangeUser.joins(:feedbacks)
                              .where('still_alive = true')
                              .where('stack_exchange_users.site_id = 1')
                              .where('feedbacks.feedback_type LIKE \'%t%\'')
                              .includes(:site)
                              .group(:user_id)
                              .order(Arel.sql('created_at DESC'))
                              .first(100)
  end

  def show
    @posts = @user.posts
  end

  def on_site
    @site = Site.find params[:site]
    @users = StackExchangeUser.joins(:feedbacks).where(site: @site, still_alive: true)
                              .where("feedbacks.feedback_type LIKE '%t%'").group(Arel.sql('stack_exchange_users.id'))
                              .order('(stack_exchange_users.question_count + stack_exchange_users.answer_count) DESC'\
                                     ', stack_exchange_users.reputation DESC')
                              .paginate(page: params[:page], per_page: 100)
  end

  def sites
    @sites = Site.all
  end

  def dead
    @user = StackExchangeUser.find params[:id]

    if @user.update(still_alive: false)
      render plain: 'ok', status: :ok
    else
      render plain: 'fail', status: :conflict
    end
  end

  def update_data
    site = Site.find params[:site]
    api_site_param = site.site_url.split('/')[-1].split('.')[0]
    Thread.new do
      live_ids = []
      StackExchangeUser.where(site: site, still_alive: true).in_groups_of(100).each do |group|
        ids = group.compact.map(&:user_id).join(';')
        filter = '!40D.p)TeT8rA79vLR'
        uri = "https://api.stackexchange.com/2.2/users/#{ids}?site=#{api_site_param}&key=#{AppConfig['stack_exchange']['key']}&filter=#{filter}"

        response = HTTParty.get(uri)
        jsn = response.parsed_response
        live_ids += jsn['items'].map { |u| u['user_id'] }
        sleep(jsn['backoff']) if jsn['backoff']
      end

      StackExchangeUser.where(site: site).where.not(user_id: live_ids).update_all(still_alive: false)
      site.update(last_users_update: DateTime.now)
    end

    flash[:info] = 'Data updates have been queued; check back in a few minutes.'
    redirect_to url_for(controller: :stack_exchange_users, action: :on_site, site: params[:site])
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_stack_exchange_user
    @user = StackExchangeUser.joins(:site).select(Arel.sql('stack_exchange_users.*, sites.site_logo')).find(params[:id])
  rescue
    @user = StackExchangeUser.find(params[:id])
  end
end
