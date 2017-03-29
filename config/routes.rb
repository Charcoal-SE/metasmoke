Rails.application.routes.draw do
  root to: "dashboard#index"
  get "dashboard", to: "dashboard#index"

  mount ActionCable.server => '/cable'

  scope "/authentication" do
    get 'status', to: 'authentication#status', as: :authentication_status
    get 'redirect_target', to: 'authentication#redirect_target'
    get 'login_redirect_target', to: 'authentication#login_redirect_target'
  end

  scope "/users" do
    root to: 'admin#users', as: :users
    get 'username', to: 'users#username', as: :users_username
    post 'username', to: "users#set_username"
    get 'apps', to: 'users#apps', as: :users_apps
    delete 'revoke_app', to: 'users#revoke_app', as: :users_revoke_app
  end

  scope "/review" do
    root to: "review#index", as: :review
    post 'feedback', to: "review#add_feedback", as: :review_feedback
  end

  get 'stack_exchange_users/index'
  get 'stackusers/:id', to: "stack_exchange_users#show", as: :stack_exchange_user

  get 'search', to: 'search#search_results'

  scope "/graphs" do
    root to: "graphs#index", as: :graphs
    get 'flagging_results', :to => 'graphs#flagging_results'
    get 'flagging_timeline', :to => 'graphs#flagging_timeline'
    get 'reports_hours', :to => 'graphs#reports_by_hour'
    get 'reports_sites', :to => 'graphs#reports_by_site'
    get 'reports_hod', :to => 'graphs#reports_by_hour_of_day'
    get 'ttd', :to => 'graphs#time_to_deletion'
    get 'dttd', :to => 'graphs#detailed_ttd'
    get 'monthly_ttd', :to => 'graphs#monthly_ttd'
  end

  get "status", to: "status#index"
  get "status/code.json", to: "code_status#api"
  get "status/code", as: :code_status, to: "code_status#index"
  get "smoke_detector/:id/statistics", to: "statistics#index", as: :smoke_detector_statistics
  delete 'smoke_detector/:id', :to => 'smoke_detectors#destroy'
  post 'smoke_detector/:id/force_failover', to: 'smoke_detectors#force_failover', as: :smoke_detector_force_failover
  get 'smoke_detector/audits', :to => 'smoke_detectors#audits'
  post "statistics.json", to: "statistics#create"

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

  get 'admin/invalidate_tokens', to: 'authentication#invalidate_tokens'
  post 'admin/invalidate_tokens', to: 'authentication#send_invalidations'

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
  get "post/:id/eligible_flaggers", to: 'flag_log#eligible_flaggers', as: :post_eligible_flaggers
  post "post/:id/index_feedback", to: "posts#reindex_feedback"
  post "post/:id/spam_flag", to: 'posts#cast_spam_flag'

  get "users", to: "stack_exchange_users#index"

  post 'feedbacks.json', to: "feedbacks#create"
  post 'posts.json', to: "posts#create"
  post 'deletion_logs.json', to: "deletion_logs#create"
  post "status-update.json", to: "status#status_update"

  get "reason/:id", to: "reasons#show", as: :reason
  get "reason/:id/site_chart", to: "reasons#sites_chart", as: :reason_site_chart
  get "reason/:id/accuracy_chart", to: "reasons#accuracy_chart", as: :reason_accuracy_chart

  get "posts/recent.json", to: "posts#recentpostsapi"
  post "posts/add_feedback", to: "review#add_feedback"

  scope "/github" do
    post 'status_hook', to: 'github#status_hook', as: :github_status_hook
    post 'pull_request_hook', to: 'github#pull_request_hook', as: :github_pull_request_hook
    post 'ci_hook', to: 'github#ci_hook', as: :github_ci_hook
    post 'update_deploy_to_master', to: 'github#update_deploy_to_master', as: :github_update_deploy_to_master
    post 'metasmoke_push_hook', to: 'github#metasmoke_push_hook', as: :github_metasmoke_push_hook
    post 'gollum', to: 'github#gollum_hook', as: :github_gollum_hook
  end

  scope "/api" do
    root to: 'api#api_docs'

    get  'filters', :to => 'api#filter_generator'
    get  'filter_fields', :to => 'api#filter_fields'
    get  'smoke_detectors/status', :to => 'api#current_status'
    get  'posts/urls', :to => 'api#posts_by_url'
    post 'posts/urls', :to => 'api#posts_by_url'
    get  'posts/feedback', :to => 'api#posts_by_feedback'
    get  'posts/undeleted', :to => 'api#undeleted_posts'
    get  'posts/site', :to => 'api#posts_by_site'
    get  'posts/between', :to => 'api#posts_by_daterange'
    get  'posts/search', :to => 'api#search_posts'
    get  'posts/:ids', :to => 'api#posts'
    get  'post/:id/feedback', :to => 'api#post_feedback'
    get  'post/:id/reasons', :to => 'api#post_reasons'
    get  'post/:id/valid_feedback', :to => 'api#post_valid_feedback'
    get  'reasons/:ids', :to => 'api#reasons'
    get  'reason/:id/posts', :to => 'api#reason_posts'
    get  'blacklist', :to => 'api#blacklisted_websites'
    get  'users/code_privileged', :to => 'api#users_with_code_privs'

    post 'w/post/:id/feedback', :to => 'api#create_feedback'
    post 'w/post/report', :to => 'api#report_post'
    post 'w/post/:id/spam_flag', :to => 'api#spam_flag'
  end

  scope "/oauth" do
    get 'request', to: 'micro_auth#token_request', as: :oauth_request
    post 'authorize', to: 'micro_auth#authorize', as: :oauth_authorize
    get 'authorized', to: 'micro_auth#authorized', as: :oauth_authorized
    get 'reject', to: 'micro_auth#reject', as: :oauth_reject
    get 'token', to: 'micro_auth#token', as: :oauth_token
    get 'invalid_key', to: 'micro_auth#invalid_key', as: :oauth_invalid_key
  end

  scope "/dev" do
    post 'update_sites', to: 'developer#update_sites', as: :dev_update_sites
    get 'prod_log', to: 'developer#production_log', as: :dev_prod_log
    get 'blank', to: 'developer#blank_page', as: :dev_blank
    get 'websockets', to: 'developer#websocket_test'
    post 'websockets', to: 'developer#send_websocket_test'
  end

  # flagging
  get 'flagging', :to => 'flag_settings#dashboard'
  scope "/flagging" do
    post "smokey_disable", :to => 'flag_settings#smokey_disable_flagging'
    resources :flag_settings, :path => "/settings", :except => [:show]

    get 'ocs', :to => 'flag_conditions#one_click_setup'
    post 'run_ocs', :to => 'flag_conditions#run_ocs'

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
    get 'users/overview', :to => 'flag_conditions#user_overview', :as => :user_overview

    scope "/audits" do
      get "settings", :to => 'flag_settings#audits', :as => "flag_settings_audits"
    end
  end

  devise_for :users
end
