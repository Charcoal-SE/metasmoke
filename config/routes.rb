Rails.application.routes.draw do
  get 'authentication/status'

  get 'authentication/redirect_target'

  mount ActionCable.server => '/cable'

  get 'users/username'
  post 'users/username', to: "users#set_username"
  get 'users/apps', to: 'users#apps'
  delete 'users/revoke_app', to: 'users#revoke_app'

  get 'review', to: "review#index"
  post 'review/feedback', to: "review#add_feedback"

  get 'stack_exchange_users/index'
  get 'stackusers/:id', to: "stack_exchange_users#show", as: "stack_exchange_user"

  get 'search', to: 'search#search_results'

  get "graphs", to: "graphs#index"
  get 'graphs/flagging_results', :to => 'graphs#flagging_results'
  get 'graphs/flagging_timeline', :to => 'graphs#flagging_timeline'
  get 'graphs/reports_hours', :to => 'graphs#reports_by_hour'
  get 'graphs/reports_sites', :to => 'graphs#reports_by_site'
  get 'graphs/reports_hod', :to => 'graphs#reports_by_hour_of_day'
  get 'graphs/ttd', :to => 'graphs#time_to_deletion'

  get "status", to: "status#index"
  get "smoke_detector/:id/statistics", to: "statistics#index", as: :smoke_detector_statistics
  delete 'smoke_detector/:id', :to => 'smoke_detectors#destroy'
  post 'smoke_detector/:id/force_failover', to: 'smoke_detectors#force_failover', as: :smoke_detector_force_failover
  get 'smoke_detector/audits', :to => 'smoke_detectors#audits'
  post "statistics.json", to: "statistics#create"

  get "users", to: 'admin#users'

  get 'admin', to: 'admin#index'
  get 'admin/invalidated', to: 'admin#recently_invalidated'
  get 'admin/user_feedback', to: 'admin#user_feedback'
  get 'admin/api_feedback', to: 'admin#api_feedback'
  get 'admin/flagged', to: 'admin#flagged'
  post 'admin/clear_flag', to: 'admin#clear_flag'
  get 'admin/users', to: 'admin#users'
  get 'admin/ignored_users', to: 'admin#ignored_users'
  patch 'admin/ignore/:id', to: 'admin#ignore'
  patch 'admin/unignore/:id', to: 'admin#unignore'
  delete 'admin/destroy_ignored/:id', to: 'admin#destroy_ignored'
  get 'admin/permissions'
  put 'admin/permissions/update', to: "admin#update_permissions"

  get 'admin/new_key', to: 'api_keys#new'
  post 'admin/new_key', to: 'api_keys#create'
  get 'admin/keys', to: 'api_keys#index'
  get 'admin/keys/mine', to: 'api_keys#mine'
  get 'admin/edit_key/:id', to: 'api_keys#edit'
  patch 'admin/edit_key/:id', to: 'api_keys#update'
  get 'admin/owner_edit/:id', to: 'api_keys#owner_edit'
  patch 'admin/owner_edit/:id', to: 'api_keys#owner_update'
  delete 'admin/revoke_write', to: 'api_keys#revoke_write_tokens'
  delete 'admin/owner_revoke', to: 'api_keys#owner_revoke'

  get "posts", to: "posts#index"
  get "posts/latest", to: "posts#latest"
  get "posts/by-url", to: "posts#by_url"
  post 'posts/needs_admin', to: 'posts#needs_admin'
  get "post/:id/feedback/clear", to: "feedbacks#clear", as: :clear_post_feedback
  delete "feedback/:id/delete", to: "feedbacks#delete", as: :delete_feedback

  get "post/:id", to: "posts#show"
  get "post/:id/body", to: "posts#body"
  get "post/:id/feedbacks.json", to: 'posts#feedbacksapi'
  get "post/:id/flag_logs", to: 'flag_log#by_post', as: :post_flag_logs
  post "post/:id/index_feedback", to: "posts#reindex_feedback"

  get "users", to: "stack_exchange_users#index"

  post 'feedbacks.json', to: "feedbacks#create"
  post 'posts.json', to: "posts#create"
  post 'deletion_logs.json', to: "deletion_logs#create"
  post "status-update.json", to: "status#status_update"

  get "dashboard", to: "dashboard#index"

  get "reason/:id", to: "reasons#show", as: :reason
  get "reason/:id/site_chart", to: "reasons#sites_chart", as: :reason_site_chart
  get "reason/:id/accuracy_chart", to: "reasons#accuracy_chart", as: :reason_accuracy_chart

  get "posts/recent.json", to: "posts#recentpostsapi"
  post "posts/add_feedback", to: "review#add_feedback"

  post 'github/status_hook'
  post 'github/pull_request_hook'
  post 'github/ci_hook'
  post 'github/update_deploy_to_master'

  root to: "dashboard#index"

  get  'api', :to => 'dashboard#api_docs'
  get  'api/filters', :to => 'api#filter_generator'

  get  'api/smoke_detectors/status', :to => 'api#current_status'
  get  'api/posts/urls', :to => 'api#posts_by_url'
  post 'api/posts/urls', :to => 'api#posts_by_url'
  get  'api/posts/feedback', :to => 'api#posts_by_feedback'
  get  'api/posts/undeleted', :to => 'api#undeleted_posts'
  get  'api/posts/site', :to => 'api#posts_by_site'
  get  'api/posts/between', :to => 'api#posts_by_daterange'
  get  'api/posts/search', :to => 'api#search_posts'
  get  'api/posts/:ids', :to => 'api#posts'
  get  'api/post/:id/feedback', :to => 'api#post_feedback'
  get  'api/post/:id/reasons', :to => 'api#post_reasons'
  get  'api/post/:id/valid_feedback', :to => 'api#post_valid_feedback'
  get  'api/reasons/:ids', :to => 'api#reasons'
  get  'api/reason/:id/posts', :to => 'api#reason_posts'
  get  'api/blacklist', :to => 'api#blacklisted_websites'
  get  'api/users/code_privileged', :to => 'api#users_with_code_privs'

  post 'api/w/post/:id/feedback', :to => 'api#create_feedback'
  post 'api/w/post/report', :to => 'api#report_post'

  get 'oauth/request', :to => 'micro_auth#token_request'
  post 'oauth/authorize', :to => 'micro_auth#authorize'
  get 'oauth/authorized', :to => 'micro_auth#authorized'
  get 'oauth/reject', :to => 'micro_auth#reject'
  get 'oauth/token', :to => 'micro_auth#token'
  get 'oauth/invalid_key', :to => 'micro_auth#invalid_key'

  post 'dev/update_sites', :to => 'developer#update_sites'
  get 'dev/prod_log', :to => 'developer#production_log'
  get 'dev/blank', :to => 'developer#blank_page'

  # flagging
  get 'flagging', :to => 'flag_settings#dashboard'
  scope "/flagging" do
    post "smokey_disable", :to => 'flag_settings#smokey_disable_flagging'
    resources :flag_settings, :path => "/settings", :except => [:show]

    get 'conditions/all', :to => 'flag_conditions#full_list'
    get 'conditions/preview', :to => 'flag_conditions#preview'
    get 'conditions/sandbox', :to => 'flag_conditions#sandbox'
    resources :flag_conditions, :path => "/conditions", :except => [:show]
    patch 'conditions/:id/enable', :to => "flag_conditions#enable", :as => :flag_conditions_enable

    get 'preferences/user/:user', :to => 'user_site_settings#for_user'
    post 'preferences/enable', :to => 'user_site_settings#enable_flagging'
    resources :user_site_settings, :path => "/preferences", :except => [:show]

    get 'logs', :to => 'flag_log#index', :as => :flag_logs
    get 'logs/unflagged', :to => 'flag_log#not_flagged', :as => :unflagged_logs
    get 'users/:user_id/logs', :to => 'flag_log#index', :as => :flag_logs_by_user

    scope "/audits" do
      get "settings", :to => 'flag_settings#audits', :as => "flag_settings_audits"
    end
  end

  devise_for :users
end
