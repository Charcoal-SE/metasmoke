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

  get "status", to: "status#index"

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

  get "/users", to: "stack_exchange_users#index"

  post 'feedbacks.json', to: "feedbacks#create"
  post 'posts.json', to: "posts#create"
  post 'deletion_logs.json', to: "deletion_logs#create"
  post "status-update.json", to: "status#status_update"

  get "dashboard", to: "dashboard#index"

  get "reason/:id", to: "reasons#show"
  get "reason/:id/site_chart", to: "reasons#sites_chart", as: :reason_site_chart
  get "reason/:id/accuracy_chart", to: "reasons#accuracy_chart", as: :reason_accuracy_chart

  get "posts/recent.json", to: "posts#recentpostsapi"
  post "posts/add_feedback", to: "review#add_feedback"

  get 'blacklist', to: 'blacklist#index'
  get 'blacklist/add_website', to: 'blacklist#add_website'
  post 'blacklist/add_website', to: 'blacklist#create_website'
  delete 'blacklist/website/:id', to: 'blacklist#deactivate_website'

  post 'github/hook'

  root to: "dashboard#index"

  get 'api', :to => 'dashboard#api_docs'
  get 'api/smoke_detectors/status', :to => 'api#current_status'
  get 'api/posts/url', :to => 'api#posts_by_url'
  get 'api/posts/feedback', :to => 'api#posts_by_feedback'
  get 'api/posts/undeleted', :to => 'api#undeleted_posts'
  get 'api/posts/site', :to => 'api#posts_by_site'
  get 'api/posts/between', :to => 'api#posts_by_daterange'
  get 'api/posts/search', :to => 'api#search_posts'
  get 'api/posts/:ids', :to => 'api#posts'
  get 'api/post/:id/feedback', :to => 'api#post_feedback'
  get 'api/post/:id/reasons', :to => 'api#post_reasons'
  get 'api/post/:id/valid_feedback', :to => 'api#post_valid_feedback'
  get 'api/reasons/:ids', :to => 'api#reasons'
  get 'api/reason/:id/posts', :to => 'api#reason_posts'
  get 'api/blacklist', :to => 'api#blacklisted_websites'
  get 'api/users/code_privileged', :to => 'api#users_with_code_privs'

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

  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
