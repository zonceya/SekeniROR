Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      get '/home', to: 'home#index'
      
      # Schools
      get '/schools', to: 'schools#index'
      get '/schools/:id', to: 'schools#show'
      get '/schools/:id/items', to: 'schools#items'
      
      # Brands
      get '/brands', to: 'brands#index'
      get '/brands/:id', to: 'brands#show'
      get '/brands/:id/items', to: 'brands#items'
      
      # Sale
      get '/sale', to: 'sales#index'
      get '/sale/items', to: 'sales#items'
      
      # Categories
      get '/categories', to: 'categories#index'
      get '/categories/:id/items', to: 'categories#items'
      get '/items', to: 'items#index' 
      # Provinces & Towns for filtering
      get '/provinces', to: 'provinces#index'
      get '/towns', to: 'towns#index'
    
      # Existing routes
      resources :items, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :mark_as_sold
          post :reserve_item
        end
      end
      
      resources :brands, only: [:index]
      resources :categories, only: [:index]
      resources :item_types, only: [:index]
      resources :item_sizes, only: [:index]
      resources :schools, only: [:index]
      resources :tags, only: [:index]
      resources :item_tags, only: [:index]
      resources :banners, only: [:index, :create, :update, :destroy]
      # ================================
      # 👤 User routes
      # ================================
      post 'users/sign_in', to: 'users#sign_in'
      get 'users/profile', to: 'users#profile'
      put 'users/update_mobile', to: 'users#update_mobile'
      post 'users/disable', to: 'users#disable'
      put 'users/reactivate', to: 'users#reactivate'
      post 'users/firebase_token', to: 'users#update_firebase_token'
      get 'users/:user_id/ratings', to: 'users#user_ratings' # ✅ Fixed: moved from orders

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
      # 💬 Chat routes
      # ================================
      resources :chat_rooms, only: [:index, :show, :create] do
        resources :chat_messages, only: [:index, :create]
        post 'mark_read', to: 'chat_messages#mark_as_read'
      end
      mount ActionCable.server => '/cable'

      # ================================
      # 🧾 Order & Payment routes
      # ================================
      resources :orders, only: [:create, :show] do
        member do
          patch :addresses
          post :cancel
          post :pay
          post :dispatch
          post :mark_delivered
          post :confirm_receipt
          post :dispute
          post :submit_payment_proof
          
          # ✅ REFUND ROUTES - CORRECTED
            post 'cancel_order', to: 'refunds#cancel_order'
            post 'dispute', to: 'refunds#dispute'
            get 'refund_status', to: 'refunds#show'
          
          
          # 🔐 PIN VERIFICATION ROUTES
          post 'generate_pin', to: 'pin_verifications#generate_pin'
          get 'pin_verification', to: 'pin_verifications#show'
          get 'seller_pin', to: 'pin_verifications#seller_pin' 
          get 'transaction_summary', to: 'pin_verifications#transaction_summary'
          post 'resend_pin', to: 'pin_verifications#resend'
          post 'cancel_pin', to: 'pin_verifications#cancel'
          
          # PAYMENT ROUTES
          post 'initiate_payment', to: 'payments#initiate'
          get 'payment_status', to: 'payments#status'
          get 'payment_transactions', to: 'payments#transactions'
          post 'upload_payment_proof', to: 'payments#upload_proof'
          post 'confirm_payment', to: 'payments#confirm_payment'
        end
        
        resources :ratings, only: [:index, :create]
      end

      # ================================
      # ⭐ Rating routes
      # ================================
      get 'shops/:shop_id/ratings', to: 'ratings#shop_ratings'

      # ================================
      # 💰 WALLET ROUTES
      # ================================
      resource :wallet, only: [:show] do
        get 'transactions', on: :member
        resources :bank_accounts, only: [:index, :create, :show, :update, :destroy]
        resources :transfer_requests, only: [:index, :create]
      end

      # ================================
      # 🔐 PIN VERIFICATION ROUTES
      # ================================
      resources :pin_verifications, only: [] do
        member do
          post 'verify_pin', to: 'pin_verifications#verify_pin'
        end
      end

      # ================================
      # 🏦 BANK WEBHOOKS
      # ================================
      post '/bank_webhooks/payment_received', to: 'bank_webhooks#payment_received'

      # ================================
      # 🔔 Notification routes
      # ================================
      resources :notifications, only: [:index] do
        member do
          put :read, to: 'notifications#mark_as_read'
        end
        collection do
          get :unread_count, to: 'notifications#unread_count'
        end
      end

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
        
        # ADMIN PAYMENT ROUTES
        resources :payments, only: [] do
          collection do
            get :flagged
            get :proofs
            get 'bank_details', to: 'payments#bank_details'
          end
          member do
            patch :approve_proof
            patch :reject_proof
            post :manual_verification
          end
        end

        # ADMIN TRANSFER REQUESTS
        resources :transfer_requests, only: [:index, :update] do
          post 'process', on: :member
        end

        # ✅ ADMIN REFUND & DISPUTE ROUTES
        resources :refunds, only: [:index, :show, :update] do
          member do
            post 'approve', to: 'refunds#approve_refund'
            post 'reject', to: 'refunds#reject_refund'
            post 'process', to: 'refunds#process_refund'
          end
        end

        resources :disputes, only: [:index, :show, :update] do
          member do
            post 'resolve_buyer', to: 'disputes#resolve_for_buyer'
            post 'resolve_seller', to: 'disputes#resolve_for_seller'
            post 'escalate', to: 'disputes#escalate'
          end
        end
      end
    end
  end
end