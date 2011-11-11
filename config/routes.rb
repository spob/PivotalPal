PivotalPal::Application.routes.draw do
  get "tenants/edit"

  get "tenants/update"

  get "profile/edit"

  get "profile/update"

  devise_for :users

  resources :logons, :only => [:index]
  resources :org_users, :only => [:new, :create, :index]
  resources :passwds, :only => [:edit, :update]
  resources :periodic_jobs, :only => [:index] do
    member do
      post :rerun
      post :run_now
    end
    collection do
      post :execute
    end
  end
  resources :profile, :only => [:edit, :update]
  resources :projects do
    member do
      post :print
      post :refresh
      post :renumber
      get :select_to_print
      get :stats
      get :storyboard
    end
  end
  resources :super_users, :only => [:index, :edit, :update]
  resources :tenants, :only => [:edit, :update]
  resources :users, :except => [:destroy, :create] do
    member do
      post :create_new
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "projects#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
