Rails.application.routes.draw do
  namespace :api do
    # ================================
    # ANDROID COMPATIBILITY ROUTES (without v1)
    # These match what the Android app expects
    # ================================
    post 'auth/signup', to: 'v1/users#sign_up'
    
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
      
      # ================================
      # 🔍 FILTER ROUTES
      # ================================
      get '/filters/options', to: 'filters#options'
      get '/filters/categories', to: 'filters#categories'
      get '/filters/subcategories', to: 'filters#subcategories'
      get '/filters/genders', to: 'filters#genders'
      get '/filters/conditions', to: 'filters#conditions'
      get '/filters/colors', to: 'filters#colors'
      get '/filters/sizes', to: 'filters#sizes'
      get '/filters/brands', to: 'filters#brands'
      get '/filters/tags', to: 'filters#tags'
      
      # ================================
      # 🏪 SHOP ROUTES
      # ================================
      resource :shop, only: [:show, :update]
      get 'shops/:id', to: 'shops#public_show', as: :public_shop
      get 'shops/:id/items', to: 'shops#items'
      
      # ================================
      # 🛒 ITEM ROUTES
      # ================================
      resources :items, only: [:index, :show, :create] do
        collection do
          get :shop_items
          get :viewAllShopItems
          post :createItems
        end
        
        member do
          get :viewShopItem
          post :reserve_item
          put :updateItem
          put :update   
          delete :deleteItem
          patch :mark_as_sold
          post :hold
          delete :release
          
          post 'images', to: 'items#add_images'
          delete 'images/:image_id', to: 'items#remove_image'
        end
      end
      
      # ================================
      # 🎯 RECOMMENDATIONS ROUTES
      # ================================
      get 'recommendations/home', to: 'recommendations#home'
      get 'recommendations/uniform', to: 'recommendations#uniform'
      get 'recommendations/sport', to: 'recommendations#sport'
      get 'recommendations/recent', to: 'recommendations#recent'
      get 'recommendations/recommended/all', to: 'recommendations#recommended_all'
      get 'recommendations/essentials/all', to: 'recommendations#essentials_all'
      get 'recommendations/trending/all', to: 'recommendations#trending_all'
      get 'recommendations/recent/all', to: 'recommendations#recent_all'
      
      post 'recommendations/track_view', to: 'recommendations#track_view'
      post 'recommendations/track_click', to: 'recommendations#track_click'
      
      # ================================
      # 📋 MASTER DATA ROUTES
      # ================================
      resources :brands, only: [:index]
      resources :categories, only: [:index]
      resources :main_categories, only: [:index] do
        member do
          get :sub_categories
        end
      end
      resources :sub_categories, only: [:index]
      resources :item_types, only: [:index]
      resources :item_sizes, only: [:index]
      resources :schools, only: [:index]
      resources :tags, only: [:index]
      resources :item_tags, only: [:index]
      resources :banners, only: [:index, :create, :update, :destroy]
      resources :item_conditions, only: [:index]
      resources :item_colors, only: [:index]
      resources :locations, only: [:index]
      get 'genders', to: 'genders#index'
      get 'locations', to: 'locations#index'
      get 'all_reference_data', to: 'reference_data#index'
      get '/categories/:id/filter_config', to: 'filters#category_filter_config'
      get '/filters/global_config', to: 'filters#global_filter_config'
      get '/provinces', to: 'provinces#index'
      get '/towns', to: 'towns#index'
      
      # ================================
      # 👤 USER ROUTES (v1 API)
      # ================================
      post 'users/sign_in', to: 'users#sign_in'
      post 'users/signup', to: 'users#sign_up'
      
      # 🔥 FIREBASE AUTHENTICATION ROUTES (ADD THESE)
      post 'users/firebase_auth', to: 'users#firebase_auth'
      post 'users/firebase_token', to: 'users#update_firebase_token'    
      
      get 'users/profile', to: 'users#profile'
      put 'users/update_mobile', to: 'users#update_mobile'
      post 'users/disable', to: 'users#disable'
      put 'users/reactivate', to: 'users#reactivate'
      get 'users/:user_id/ratings', to: 'users#user_ratings'
      put 'users/update_profile_picture', to: 'users#update_profile_picture'
      get 'users/:id', to: 'users#show'
      post 'auth/refresh', to: 'users#refresh_token'
      # ================================
      # 🏫 USER SCHOOL ROUTES
      # ================================
      resources :user_schools, only: [:create, :update, :destroy] do
        collection do
          get :current
        end
      end

      # ================================
      # 💬 CHAT ROUTES
      # ================================
      resources :chat_rooms, only: [:index, :show, :create] do
        resources :chat_messages, only: [:index, :create]
        post 'mark_read', to: 'chat_messages#mark_as_read'
      end
      mount ActionCable.server => '/cable'

      # ================================
      # 🧾 ORDER & PAYMENT ROUTES
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
          
          post 'cancel_order', to: 'refunds#cancel_order'
          post 'dispute', to: 'refunds#dispute'
          get 'refund_status', to: 'refunds#show'
          
          post 'generate_pin', to: 'pin_verifications#generate_pin'
          get 'pin_verification', to: 'pin_verifications#show'
          get 'seller_pin', to: 'pin_verifications#seller_pin' 
          get 'transaction_summary', to: 'pin_verifications#transaction_summary'
          post 'resend_pin', to: 'pin_verifications#resend_pin'
          post 'cancel_pin', to: 'pin_verifications#cancel_pin'
          
          post 'initiate_payment', to: 'payments#initiate'
          get 'payment_status', to: 'payments#status'
          get 'payment_transactions', to: 'payments#transactions'
          post 'upload_payment_proof', to: 'payments#upload_proof'
          post 'confirm_payment', to: 'payments#confirm_payment'
        end
        
        resources :ratings, only: [:index, :create]
      end

      # ================================
      # ⭐ RATING ROUTES
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
      # 🔔 NOTIFICATION ROUTES
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
      # 🔐 ADMIN ROUTES
      # ================================
      namespace :admin do
        post 'auth/signup', to: 'auth#signup'
        post 'auth/login', to: 'auth#login'
        post 'auth/logout', to: 'auth#logout'
        post 'auth/forgot_password', to: 'auth#forgot_password'
        post 'auth/reset_password', to: 'auth#reset_password'

        patch 'users/:id/update_password', to: 'users#update_password'
        resources :users, only: [:index, :show, :update, :destroy] do
          post :reactivate, on: :member
        end
    
        resources :items, only: [] do
          collection do
            get :adminViewAllItems
          end
          member do
            delete :adminDeleteItem
          end
        end
     
        resources :orders, only: [:index, :show] do
          collection do
            get :bulk_index
          end
          member do
            patch :update_status
          end
        end
        
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

        resources :transfer_requests, only: [:index, :update] do
          post 'process', on: :member
        end

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