# frozen_string_literal: true

# routes.rb style guidance:
#
# - Root at the top
# - Unscoped routes next; group them logically
# - Throw everything else in a scope, alphabetically ordered.
# - Within a scope, unscoped routes go _after_ everything else.
# - Unscoped mounts at the bottom.
#
# RubyMine hint: Within the draw block, Ctrl-Shift-Minus followed by Ctrl-= (or cmd, whatever system you're on)
# will collapse everything and then expand the top level again so you just see unscoped routes plus scopes. Makes
# it much easier to see where everything is.
Rails.application.routes.draw do
  # Needs both with and without :as, ref Charcoal-SE/metasmoke#247
  root               to: 'dashboard#new_dash',  as: :dashboard
  root               to: 'dashboard#new_dash'

  resources :dumps

  get    'sites/dash',            to: 'dashboard#site_dash',        as: :site_dash

  get    'search',                to: 'search#index'
  get    'search_fast',           to: 'search#index_fast'
  get    'reasons',               to: 'dashboard#index',            as: :reasons
  get    'flagging',              to: 'flag_settings#dashboard',    as: :flagging

  get    'query-times',           to: 'dashboard#query_times',      as: :query_times
  post   'query-times/reset/:id', to: 'dashboard#reset_query_time', as: :reset_query_time

  post   'statistics.json',       to: 'statistics#create'
  post   'feedbacks.json',        to: 'feedbacks#create'
  post   'posts.json',            to: 'posts#create'
  post   'deletion_logs.json',    to: 'deletion_logs#create'
  post   'status-update.json',    to: 'status#status_update'

  delete 'feedback/:id/delete',   to: 'feedbacks#delete',           as: :delete_feedback

  devise_for :users, controllers: { sessions: 'custom_sessions', registrations: 'custom_registrations' }
  devise_scope :user do
    get  'users/2fa/login', to: 'custom_sessions#verify_2fa'
    post 'users/2fa/login', to: 'custom_sessions#verify_code'
  end

  scope 'abuse' do
    scope 'contacts' do
      root               to: 'abuse_contacts#index',   as: :abuse_contacts
      post   'new',      to: 'abuse_contacts#create',  as: :create_abuse_contact
      get    ':id',      to: 'abuse_contacts#show',    as: :abuse_contact
      get    ':id/edit', to: 'abuse_contacts#edit',    as: :edit_abuse_contact
      patch  ':id/edit', to: 'abuse_contacts#update',  as: :update_abuse_contact
      delete ':id',      to: 'abuse_contacts#destroy', as: :destroy_abuse_contact
    end

    scope 'statuses' do
      root               to: 'abuse_report_statuses#index',   as: :abuse_statuses
      post   'new',      to: 'abuse_report_statuses#create',  as: :create_abuse_status
      get    ':id',      to: 'abuse_report_statuses#show',    as: :abuse_status
      get    ':id/edit', to: 'abuse_report_statuses#edit',    as: :edit_abuse_status
      patch  ':id/edit', to: 'abuse_report_statuses#update',  as: :update_abuse_status
      delete ':id',      to: 'abuse_report_statuses#destroy', as: :destroy_abuse_status
    end

    scope 'reports' do
      root                   to: 'abuse_reports#index',         as: :abuse_reports
      get    'new',          to: 'abuse_reports#new',           as: :new_abuse_report
      post   'new',          to: 'abuse_reports#create',        as: :create_abuse_report
      get    'shared/:uuid', to: 'abuse_reports#public_link',   as: :shared_abuse_report
      get    ':id',          to: 'abuse_reports#show',          as: :abuse_report
      patch  ':id/edit',     to: 'abuse_reports#update',        as: :update_abuse_report
      post   ':id/status',   to: 'abuse_reports#update_status', as: :update_abuse_report_status
      delete ':id',          to: 'abuse_reports#destroy',       as: :destroy_abuse_report
    end

    scope 'comments' do
      post   'new',        to: 'abuse_comments#create',  as: :create_abuse_comment
      get    ':id',        to: 'abuse_comments#text',    as: :comment_abuse_text
      post   ':id/edit',   to: 'abuse_comments#update',  as: :edit_abuse_comment
      delete ':id/delete', to: 'abuse_comments#destroy', as: :delete_abuse_comment
    end
  end

  scope 'admin' do
    scope 'settings' do
      root                 to: 'site_settings#index',   as: :site_settings
      post   ':name',      to: 'site_settings#update',  as: :update_site_setting
      delete ':id/delete', to: 'site_settings#destroy', as: :destroy_site_setting
    end

    root                           to: 'admin#index'
    get    'invalidated',          to: 'admin#recently_invalidated'
    get    'user_feedback',        to: 'admin#user_feedback',               as: :admin_user_feedback
    get    'api_feedback',         to: 'admin#api_feedback'
    get    'flagged',              to: 'admin#flagged'
    post   'clear_flag',           to: 'admin#clear_flag'
    get    'users',                to: 'admin#users',                       as: :user_data
    get    'permissions',          to: 'admin#permissions',                 as: :admin_permissions
    put    'permissions/update',   to: 'admin#update_permissions'
    delete 'permissions/:user_id', to: 'admin#destroy_user'

    get    'invalidate_tokens',    to: 'authentication#invalidate_tokens'
    post   'invalidate_tokens',    to: 'authentication#send_invalidations'

    get    'new_key',              to: 'api_keys#new',                      as: :admin_new_key
    post   'new_key',              to: 'api_keys#create'
    get    'keys',                 to: 'api_keys#index'
    get    'keys/mine',            to: 'api_keys#mine'
    get    'edit_key/:id',         to: 'api_keys#edit'
    patch  'edit_key/:id',         to: 'api_keys#update'
    get    'owner_edit/:id',       to: 'api_keys#owner_edit'
    patch  'owner_edit/:id',       to: 'api_keys#owner_update'
    delete 'revoke_write',         to: 'api_keys#revoke_write_tokens'
    delete 'owner_revoke',         to: 'api_keys#owner_revoke'
    post   'keys/:id/trust',       to: 'api_keys#update_trust'
  end

  scope 'announcements' do
    root               to: 'announcements#index',  as: :announcements
    post ':id/expire', to: 'announcements#expire', as: :announcements_expire
    get  'new',        to: 'announcements#new'
    post 'new',        to: 'announcements#create'
    post 'enable',     to: 'users#set_announcement_emails'
  end

  scope 'api' do
    root                            to: 'api#api_docs',              as: :api_docs
    get  'filters',                 to: 'api#filter_generator'
    post 'filters',                 to: 'api#calculate_filter'

    get  'filter_fields',           to: 'api#filter_fields'
    get  'stats/last_week',         to: 'api#spam_last_week'
    get  'stats/detailed_ttd',      to: 'api#detailed_ttd'
    get  'smoke_detectors/status',  to: 'api#current_status'
    get  'smoke_detectors',         to: 'api#smoke_detectors'
    get  'posts/urls',              to: 'api#posts_by_url'
    post 'posts/urls',              to: 'api#posts_by_url'
    get  'posts/feedback',          to: 'api#posts_by_feedback'
    get  'posts/undeleted',         to: 'api#undeleted_posts'
    get  'posts/site',              to: 'api#posts_by_site'
    get  'posts/between',           to: 'api#posts_by_daterange'
    get  'posts/search',            to: 'api#search_posts'
    # get  'posts/search/regex',      to: 'api#regex_search'
    get  'posts/:ids',              to: 'api#posts'
    get  'post/:id/feedback',       to: 'api#post_feedback'
    get  'post/:id/reasons',        to: 'api#post_reasons'
    get  'post/:id/valid_feedback', to: 'api#post_valid_feedback'
    get  'reasons',                 to: 'api#all_reasons'
    get  'reasons/:ids',            to: 'api#reasons'
    get  'reason/:id/posts',        to: 'api#reason_posts'
    get  'blacklist',               to: 'api#blacklisted_websites'
    get  'users',                   to: 'api#users',                 as: :api_users
    get  'users/code_privileged',   to: 'api#users_with_code_privs'
    get  'post/:id/domains',        to: 'api#post_domains',          as: :api_post_domains
    get  'domains/:id/tags',        to: 'api#domain_tags',           as: :api_domain_tags

    post 'w/post/:id/feedback',     to: 'api#create_feedback'
    post 'w/post/report',           to: 'api#report_post'
    post 'w/post/:id/spam_flag',    to: 'api#spam_flag'
    post 'w/post/:id/deleted',      to: 'api#post_deleted'
    post 'w/domains/:id/add_tag',   to: 'api#add_domain_tag',        as: :api_add_domain_tag

    post 'graphql',                 to: 'graphql#execute',           as: :graphql
    get 'graphql',                  to: 'graphql#query',             as: :query_graphql
    mount GraphiQL::Rails::Engine,  at: '/graphiql',                 graphql_path: '/api/graphql', query_params: true
  end

  scope 'authentication' do
    get 'status',                to: 'authentication#status', as: :authentication_status
    get 'redirect_target',       to: 'authentication#redirect_target'
    get 'login_redirect_target', to: 'authentication#login_redirect_target'
  end

  scope 'channels' do
    post 'receive_email', to: 'channels#receive_email',     as: :channels_receive_email
    get  'email',         to: 'channels#get_email_address', as: :channels_email
    get  'link',          to: 'channels#show_link',         as: :channels_link
  end

  scope 'comments' do
    post 'new',          to: 'post_comments#create',  as: :create_comment
    get  ':id',          to: 'post_comments#text',    as: :comment_text
    post ':id/edit',     to: 'post_comments#update',  as: :edit_comment
    delete ':id/delete', to: 'post_comments#destroy', as: :delete_comment
  end

  scope 'data' do
    root             to: 'data#index',        as: :data_explorer
    get  'retrieve', to: 'data#retrieve',     as: :data_retrieve
    get  'schema',   to: 'data#table_schema', as: :data_schema

    authenticate(:user, ->(user) { user.has_role?(:core) }) do
      mount Blazer::Engine, at: 'sql'
    end
  end

  scope 'dev' do
    post 'update_sites',     to: 'developer#update_sites',         as: :dev_update_sites
    get  'prod_log',         to: 'developer#production_log',       as: :dev_prod_log
    get  'query_time_log',   to: 'developer#query_times_log',      as: :dev_query_times_log
    get  'blank',            to: 'developer#blank_page',           as: :dev_blank
    get  'layout',           to: 'developer#empty_layout',         as: :dev_layout
    get  'websockets',       to: 'developer#websocket_test'
    post 'websockets',       to: 'developer#send_websocket_test'
    post 'deploy',           to: 'developer#deploy',               as: :developer_deploy
    get  'impersonate/stop', to: 'developer#change_back',          as: :stop_impersonating
    post 'impersonate/stop', to: 'developer#verify_elevation',     as: :verify_elevation
    post 'impersonate/:id',  to: 'developer#change_users',         as: :impersonate
    post 'fcrs',             to: 'developer#run_fcrs',             as: :developer_fcrs
    post 'reindex',          to: 'developer#run_feedback_reindex', as: :developer_reindex

    scope 'request-log' do
      root                  to: 'redis_log#index'
      get 'user/:id',       to: 'redis_log#by_user',    as: :redis_log_by_user
      get 'status/:status', to: 'redis_log#by_status',  as: :redis_log_by_status
      get 'by_path/:method/:path.:format', to: 'redis_log#by_path',  as: :redis_log_by_path, constraints: { path: /.+/ }
      get 'session/:id',    to: 'redis_log#by_session', as: :redis_log_by_session
      scope 'request/:timestamp/:request_id', constraints: {:timestamp => /[^\/]+/ } do
        root to: 'redis_log#show', as: :redis_log_request
        get 'save', to: 'redis_log#save', as: :redis_log_save_request
        get 'unsave', to: 'redis_log#unsave', as: :redis_log_unsave_request
      end
    end
  end

  scope 'domains' do
    scope 'groups' do
      root               to: 'domain_groups#index',   as: :domain_groups
      get    'new',      to: 'domain_groups#new',     as: :new_domain_group
      post   'new',      to: 'domain_groups#create',  as: :create_domain_group
      get    ':id',      to: 'domain_groups#show',    as: :domain_group
      get    ':id/edit', to: 'domain_groups#edit',    as: :edit_domain_group
      patch  ':id/edit', to: 'domain_groups#update',  as: :update_domain_group
      delete ':id',      to: 'domain_groups#destroy', as: :destroy_domain_group
    end

    scope 'tags' do
      root                            to: 'domain_tags#index',           as: :domain_tags
      post   'add',                   to: 'domain_tags#add',             as: :add_domain_tag
      post   'add_post',              to: 'domain_tags#add_post',        as: :add_post_tag
      post   'add_review',            to: 'domain_tags#add_review',      as: :review_add_tag
      post   'remove',                to: 'domain_tags#remove',          as: :remove_domain_tag
      post   'remove_post',           to: 'domain_tags#remove_post',     as: :remove_post_tag
      get    'mass',                  to: 'domain_tags#mass_tagging',    as: :domain_tags_mass_tagging
      post   'mass',                  to: 'domain_tags#submit_mass_tag', as: :domain_tags_submit_tagging
      post   'merge',                 to: 'domain_tags#merge',           as: :merge_tags
      get    ':id/edit',              to: 'domain_tags#edit',            as: :edit_domain_tag
      patch  ':id/edit',              to: 'domain_tags#update',          as: :update_domain_tag
      get    ':id',                   to: 'domain_tags#show',            as: :domain_tag
      delete ':id',                   to: 'domain_tags#destroy',         as: :destroy_domain_tag
    end

    scope 'links' do
      post   'create',    to: 'domain_links#create',  as: :create_domain_link
      patch  'update',    to: 'domain_links#update',  as: :update_domain_link
      delete ':id',       to: 'domain_links#destroy', as: :destroy_domain_link
    end

    root                     to: 'spam_domains#index',             as: :spam_domains
    get    'new',            to: 'spam_domains#new',               as: :new_spam_domain
    post   'create.json',    to: 'spam_domains#create_from_post',  as: :create_spam_domain
    post   'no_post_create', to: 'spam_domains#create',            as: :create_no_post_spam_domain
    get    'query.json',     to: 'spam_domains#query',             as: :spam_domains_query
    get    ':id/edit',       to: 'spam_domains#edit',              as: :edit_spam_domain
    patch  ':id/edit',       to: 'spam_domains#update',            as: :update_spam_domain
    get    ':id',            to: 'spam_domains#show',              as: :spam_domain
    delete ':id',            to: 'spam_domains#destroy',           as: :destroy_spam_domain
  end

  scope 'flagging' do
    scope 'audits' do
      get 'settings', to: 'flag_settings#audits', as: 'flag_settings_audits'
    end

    resources :flag_settings,         path: 'settings',    except: [:show]
    resources :flag_conditions,       path: 'conditions',  except: [:show]
    resources :user_site_settings,    path: 'preferences', except: [:show]

    get   'settings/sites',           to: 'flag_settings#site_settings',        as: :flagging_site_settings
    post  'settings/sites',           to: 'flag_settings#update_site_settings', as: :update_flagging_site_settings

    post  'smokey_disable',           to: 'flag_settings#smokey_disable_flagging'

    get   'by-site',                  to: 'flag_settings#by_site',              as: :flagging_by_site

    get   'ocs',                      to: 'flag_conditions#one_click_setup'
    post  'run_ocs',                  to: 'flag_conditions#run_ocs'

    get   'conditions/all',           to: 'flag_conditions#full_list'
    get   'conditions/preview',       to: 'flag_conditions#preview'
    get   'conditions/sandbox',       to: 'flag_conditions#sandbox'

    patch 'conditions/:id/enable',    to: 'flag_conditions#enable',             as: :flag_conditions_enable
    post  'conditions/validate_user', to: 'flag_conditions#validate_user',      as: :flag_conditions_validate_user

    get   'preferences/user/:user',   to: 'user_site_settings#for_user'
    post  'preferences/enable',       to: 'user_site_settings#enable_flagging'

    get   'logs',                     to: 'flag_log#index',                     as: :flag_logs
    get   'logs/unflagged',           to: 'flag_log#not_flagged',               as: :unflagged_logs
    get   'users/:user_id/logs',      to: 'flag_log#index',                     as: :flag_logs_by_user
    get   'users/overview',           to: 'flag_conditions#user_overview',      as: :user_overview
    get   'users',                    to: 'users#flagging_enabled',             as: :flagging_users
  end

  scope 'github' do
    post 'status_hook',             to: 'github#status_hook',             as: :github_status_hook
    post 'pull_request_hook',       to: 'github#pull_request_hook',       as: :github_pull_request_hook
    post 'ci_hook',                 to: 'github#ci_hook',                 as: :github_ci_hook
    post 'update_deploy_to_master', to: 'github#update_deploy_to_master', as: :github_update_deploy_to_master
    post 'metasmoke_push_hook',     to: 'github#metasmoke_push_hook',     as: :github_metasmoke_push_hook
    post 'gollum',                  to: 'github#gollum_hook',             as: :github_gollum_hook
    post 'project_status',          to: 'github#any_status_hook',         as: :github_project_status_hook
    post 'pr_merge',                to: 'github#pullapprove_merge_hook',  as: :github_pr_merge_hook
    post 'pr_approve/:number',      to: 'github#add_pullapprove_comment', as: :github_pr_approve_comment
  end

  scope 'graphs' do
    root                     to: 'graphs#index',                  as: :graphs
    get 'flagging_results',  to: 'graphs#flagging_results',       as: :flagging_results_graph
    get 'flagging_timeline', to: 'graphs#flagging_timeline',      as: :flagging_timeline_graph
    get 'reports_hours',     to: 'graphs#reports_by_hour',        as: :reports_by_hour_graph
    get 'reports_sites',     to: 'graphs#reports_by_site'
    get 'reports_hod',       to: 'graphs#reports_by_hour_of_day'
    get 'ttd',               to: 'graphs#time_to_deletion'
    get 'dttd',              to: 'graphs#detailed_ttd'
    get 'report_counts',     to: 'graphs#report_counts',          as: :report_counts_graph
    get 'reason_counts',     to: 'graphs#reason_counts',          as: :reason_counts_graph
    get 'monthly_ttd',       to: 'graphs#monthly_ttd',            as: :monthly_ttd_graph
    get 'reports',           to: 'graphs#reports',                as: :reports_graph
    get 'af_accuracy',       to: 'graphs#af_accuracy',            as: :af_accuracy
    get 'timings/by_action/:controller_name/:action_name', to: 'graphs#query_times_graphs', as: :query_times_graph
    get 'qtimes/:controller_name/:action_name', to: 'graphs#qtimes'
  end

  scope 'magic' do
    get 'funride', to: 'dashboard#funride'
  end

  scope 'oauth' do
    get 'request',     to: 'micro_auth#token_request', as: :oauth_request
    post 'authorize',  to: 'micro_auth#authorize',     as: :oauth_authorize
    get 'authorized',  to: 'micro_auth#authorized',    as: :oauth_authorized
    get 'reject',      to: 'micro_auth#reject',        as: :oauth_reject
    get 'token',       to: 'micro_auth#token',         as: :oauth_token
    get 'invalid_key', to: 'micro_auth#invalid_key',   as: :oauth_invalid_key
  end

  scope 'post' do
    get  ':id',                   to: 'posts#show',                 as: :post
    get  ':id/body',              to: 'posts#body'
    get  ':id/feedbacks.json',    to: 'posts#feedbacksapi'
    get  ':id/flag_logs',         to: 'flag_log#by_post',           as: :post_flag_logs
    get  ':id/eligible_flaggers', to: 'flag_log#eligible_flaggers', as: :post_eligible_flaggers
    post ':id/index_feedback',    to: 'posts#reindex_feedback'
    post ':id/spam_flag',         to: 'posts#cast_spam_flag'
    post ':id/delete',            to: 'posts#delete_post',          as: :dev_delete_post
    post ':post_id/feedback',     to: 'posts#feedback',             as: :post_feedback
    get  ':id/feedback/clear',    to: 'feedbacks#clear',            as: :clear_post_feedback
    post ':id/admin_flag',        to: 'posts#needs_admin',          as: :admin_flag_post
  end

  scope 'posts' do
    root                              to: 'posts#index',            as: :posts
    get  'latest',                    to: 'posts#latest'
    get  'by-url',                    to: 'posts#by_url'
    get  'uid/:api_param/:native_id', to: 'posts#by_uid',           constraints: { api_param: %r{[^\/]+} }
    get  'by-site',                   to: 'dashboard#spam_by_site', as: :spam_by_site
    get  'recent.json',               to: 'posts#recentpostsapi'
    post 'add_feedback',              to: 'review#add_feedback'
  end

  scope 'privacy' do
    root              to: 'dashboard#privacy',         as: :data_privacy
    get 'processing', to: 'dashboard#data_processing', as: :data_processing
  end

  scope 'reason' do
    post 'description',        to: 'reasons#update_description', as: :update_reason_description
    get  ':id',                to: 'reasons#show',               as: :reason
    get  ':id/site_chart',     to: 'reasons#sites_chart',        as: :reason_site_chart
    get  ':id/accuracy_chart', to: 'reasons#accuracy_chart',     as: :reason_accuracy_chart
  end

  scope 'review' do
    root                     to: 'review_queues#index',         as: :review_queues
    get    ':name',          to: 'review_queues#queue',         as: :review_queue
    get    ':name/next',     to: 'review_queues#next_item',     as: :next_review_item
    get    ':name/history',  to: 'review_queues#reviews',       as: :review_history
    post   ':name/recheck',  to: 'review_queues#recheck_items', as: :recheck_queue_items
    get    ':name/:item_id', to: 'review_queues#item',          as: :review_item
    post   ':name/:item_id', to: 'review_queues#submit',        as: :submit_review
    delete ':name/:id',      to: 'review_queues#delete',        as: :delete_review
  end

  scope 'rss' do
    get 'v1/deleted', to: 'rss#deleted', as: :rss
  end

  scope 'smoke_detector' do
    get    'mine',               to: 'smoke_detectors#mine',           as: :smoke_detector_mine
    get    'new',                to: 'smoke_detectors#new',            as: :smoke_detector_new
    post   'create',             to: 'smoke_detectors#create',         as: :smoke_detector_create
    post   ':id/token_regen',    to: 'smoke_detectors#token_regen',    as: :smoke_detector_token_regen
    get    ':id/statistics',     to: 'statistics#index',               as: :smoke_detector_statistics
    delete ':id',                to: 'smoke_detectors#destroy',        as: :smoke_detector_delete
    post   ':id/force_failover', to: 'smoke_detectors#force_failover', as: :smoke_detector_force_failover
    post   ':id/force_pull',     to: 'smoke_detectors#force_pull',     as: :smoke_detector_force_pull
    get    'audits',             to: 'smoke_detectors#audits'
    get    'check_token/:token', to: 'smoke_detectors#check_token'
  end

  scope 'spammers' do
    root                      to: 'stack_exchange_users#index'
    get  'sites',             to: 'stack_exchange_users#sites',       as: :spammers_site_index
    get  'site',              to: 'stack_exchange_users#on_site',     as: :spammers_on_site
    post 'site/:site/update', to: 'stack_exchange_users#update_data'
    post 'dead/:id',          to: 'stack_exchange_users#dead'
    get  ':id',               to: 'stack_exchange_users#show',        as: :stack_exchange_user
  end

  scope 'spam-waves' do
    root                 to: 'spam_waves#index',   as: :spam_waves
    get    'new',        to: 'spam_waves#new',     as: :new_spam_wave
    post   'new',        to: 'spam_waves#create',  as: :create_spam_wave
    get    'preview',    to: 'spam_waves#preview', as: :preview_spam_wave
    get    ':id',        to: 'spam_waves#show',    as: :spam_wave
    get    ':id/edit',   to: 'spam_waves#edit',    as: :edit_spam_wave
    post   ':id/edit',   to: 'spam_waves#update',  as: :update_spam_wave
    post   ':id/cancel', to: 'spam_waves#cancel',  as: :cancel_spam_wave
    post   ':id/renew',  to: 'spam_waves#renew',   as: :renew_spam_wave
  end

  scope 'status' do
    root                     to: 'status#index',      as: :status
    get  'code.json', to: 'code_status#api'
    get  'code',      to: 'code_status#index', as: :code_status
    post 'kill',      to: 'status#kill',       as: :kill_smokey
  end

  scope 'users' do
    scope '2fa' do
      root                 to: 'users#tf_status'
      post 'enable',       to: 'users#enable_2fa'
      get 'enable/code',   to: 'users#enable_code'
      post 'enable/code',  to: 'users#confirm_enable_code'
      get 'disable/code',  to: 'users#disable_code'
      post 'disable/code', to: 'users#confirm_disable_code'
    end

    root                           to: 'admin#users',               as: :users
    get    'username',             to: 'users#username',            as: :users_username
    post   'username',             to: 'users#set_username',        as: :set_username
    get    'apps',                 to: 'users#apps',                as: :users_apps
    delete 'revoke_app',           to: 'users#revoke_app',          as: :users_revoke_app

    post   'update_email',         to: 'users#update_email'

    get    'denied',               to: 'users#missing_privileges',  as: :missing_privileges

    get    'migrate_token',        to: 'users#migrate_token_confirmation', as: :migrate_token_confirmation
    post   'migrate_token',        to: 'users#migrate_token',        as: :migrate_token

    get    ':id',                  to: 'users#show',                as: :dev_user, constraints: { id: /-?\d+/ }
    post   ':id/update_ids',       to: 'users#refresh_ids',         as: :update_user_chat_ids
    post   ':id/reset_pass',       to: 'users#send_password_reset', as: :send_password_reset
    post   ':id/update_mod_sites', to: 'users#update_mod_sites',    as: :update_mod_sites
  end

  # This should always be right at the end of this file, so that it doesn't override other routes.
  mount API::Base => '/api'
  mount ActionCable.server => '/cable'
end
