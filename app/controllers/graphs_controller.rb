class GraphsController < ApplicationController
  def index
    if params[:timeframe] == "all"
      @posts = Post.all
    else
      @posts = Post.where("created_at >= ?", 1.month.ago)
    end
  end

  def flagging_results
    render json: [['Fail', FlagLog.where(:success => false).count], ['Dry run', FlagLog.where(:success => true, :is_dry_run => true).count],
                  ['Success', FlagLog.where(:success => true, :is_dry_run => false).count]]
  end

  def flagging_timeline
    render json: [{name: 'Failures', data: FlagLog.where(:success => false).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count},
                  {name: 'Dry runs', data: FlagLog.where(:success => true, :is_dry_run => true).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count},
                  {name: 'Successes', data: FlagLog.where(:success => true, :is_dry_run => false).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count}]
  end
end
