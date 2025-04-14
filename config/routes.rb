Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'users#sign_in'   # User login
      get 'users/profile', to: 'users#profile'    # Get user profile
      put 'users/update-mobile', to: 'users#update_mobile'
      resource :shop, only: [:show] #

    end
  end
end
