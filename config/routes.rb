Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # ================================
      # 👤 User routes
      # ================================
      post 'users/sign_in', to: 'users#sign_in'
      get 'users/profile', to: 'users#profile'
      put 'users/update_mobile', to: 'users#update_mobile'
      post 'users/disable', to: 'users#disable'
      put 'users/reactivate', to: 'users#reactivate'
      post 'users/firebase_token', to: 'users#update_firebase_token'
      # ================================
      # 🏪 Shop & item-related routes
      # ================================
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

      # ================================
      # 📦 Custom item routes
      # ================================
      resources :items, only: [] do
        collection do
          post :createItems
          get :viewAllShopItems
        end
        member do
          get :viewShopItem
          put :updateItem
          delete :deleteItem
          patch :mark_as_sold
          post :hold
          delete :release
        end
      end

      # ================================
      # 🧾 Order & Payment routes
      # ================================
      resources :orders, only: [:create, :show] do
        member do
          patch :addresses
          post :cancel
          # REMOVED: post :initiate_payment (moved to payments controller)
          post :pay
          post :dispatch
          post :mark_delivered
          post :confirm_receipt
          post :dispute
          post :submit_payment_proof
        end
        
        # ADD THESE PAYMENT ROUTES:
        resources :payments, only: [] do
          collection do
            post :initiate
            get :status
            get :transactions
            post :upload_proof
          end
        end
      end
      
      # ADD BANK DETAILS ROUTE:
      get 'payments/bank_details', to: 'payments#bank_details'

      post '/bank_webhooks/payment_received', to: 'bank_webhooks#payment_received'

      # ================================
      # 🔐 Admin routes
      # ================================
      namespace :admin do
        # Authentication
        post 'auth/signup', to: 'auth#signup'
        post 'auth/login', to: 'auth#login'
        post 'auth/logout', to: 'auth#logout'
        post 'auth/forgot_password', to: 'auth#forgot_password'
        post 'auth/reset_password', to: 'auth#reset_password'

        # Admin User Management
        patch 'users/:id/update_password', to: 'users#update_password'
        resources :users, only: [:index, :show, :update, :destroy] do
          post :reactivate, on: :member
        end

        # Admin Item Management
        resources :items, only: [] do
          collection do
            get :adminViewAllItems
          end
          member do
            delete :adminDeleteItem
          end
        end

        # ================================
        # 🚚 Admin Order Management
        # ================================
        resources :orders, only: [:index, :show] do
          collection do
            get :bulk_index
          end
          member do
            patch :update_status
          end
        end
        
        # ADD ADMIN PAYMENT ROUTES:
        resources :payments, only: [] do
          collection do
            get :flagged
            get :proofs
          end
          member do
            patch :approve_proof
            patch :reject_proof
            post :manual_verification
          end
        end
      end
      resources :notifications, only: [:index] do
      member do
        put :read, to: 'notifications#mark_as_read'
      end
      collection do
        get :unread_count, to: 'notifications#unread_count'
      end
    end
    end
  end
end