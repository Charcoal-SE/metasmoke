Rails.application.routes.draw do
  get 'review', to: "review#index"
  post 'review/feedback', to: "review#add_feedback"

  get 'stack_exchange_users/index'

  get 'search', to: 'search#search_results'

  get "graphs", to: "graphs#index"

  get "status", to: "status#index"


  get "posts", to: "posts#index"
  get "posts/latest", to: "posts#latest"
  get "posts/by-url", to: "posts#by_url"

  get "post/:id", to: "posts#show"

  get "/users", to: "stack_exchange_users#index"

  post 'feedbacks.json', to: "feedbacks#create"
  post 'posts.json', to: "posts#create"
  post "status-update.json", to: "status#status_update"

  get "dashboard", to: "dashboard#index"

  get "reason/:id", to: "reasons#show"

  get "posts/recent.json", to: "posts#recentpostsapi"

  root to: "dashboard#index"

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
