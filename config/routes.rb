Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'users#sign_in'
      get 'users/profile', to: 'users#profile'
      put 'users/update_mobile', to: 'users#update_mobile'
      post 'users/disable', to: 'users#disable'
      put 'users/reactivate', to: 'users#reactivate'      
      resources :items, except: [:new, :edit]
      resource :shop, only: [:show]
      resources :item_types, only: [:index]
      resources :brands, only: [:index]
      resources :item_sizes, only: [:index]
      resources :item_conditions, only: [:index]
      resources :item_colors, only: [:index]
      resources :provinces, only: [:index]
      resources :locations, only: [:index]
      resources :schools, only: [:index]
      resources :categories, only: [:index]
      resources :tags, only: [:index]
      resources :item_tags, only: [:index]
      resources :items do
        member do
          patch :mark_as_sold
        end
      end
    end
  end
end
