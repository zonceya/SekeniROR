Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'users/sign_in', to: 'users#sign_in'   # User login
      get 'users/profile', to: 'users#profile'    # Get user profile
      put 'users/update-mobile', to: 'users#update_mobile'
      post 'users/disable', to: 'users#disable'
      post 'users/reactivate', to: 'users#reactivate'  # Add this route
    end
  end
end
