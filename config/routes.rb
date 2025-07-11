Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # ================================
      # 👤 User routes
      # ================================
      post 'users/sign_in', to: 'users#sign_in'            # POST /api/v1/users/sign_in
      get 'users/profile', to: 'users#profile'             # GET /api/v1/users/profile
      put 'users/update_mobile', to: 'users#update_mobile' # PUT /api/v1/users/update_mobile
      post 'users/disable', to: 'users#disable'            # POST /api/v1/users/disable
      put 'users/reactivate', to: 'users#reactivate'       # PUT /api/v1/users/reactivate

      # ================================
      # 🏪 Shop & item-related routes
      # ================================
      resource :shop, only: [:show]                        # GET /api/v1/shop
      resources :item_types, only: [:index]                # GET /api/v1/item_types
      resources :brands, only: [:index]                    # GET /api/v1/brands
      resources :item_sizes, only: [:index]                # GET /api/v1/item_sizes
      resources :item_conditions, only: [:index]           # GET /api/v1/item_conditions
      resources :item_colors, only: [:index]               # GET /api/v1/item_colors
      resources :provinces, only: [:index]                 # GET /api/v1/provinces
      resources :locations, only: [:index]                 # GET /api/v1/locations
      resources :schools, only: [:index]                   # GET /api/v1/schools
      resources :categories, only: [:index]                # GET /api/v1/categories
      resources :tags, only: [:index]                      # GET /api/v1/tags
      resources :item_tags, only: [:index]                 # GET /api/v1/item_tags

      # ================================
      # 📦 Custom item routes
      # ================================
      resources :items, only: [] do
        collection do
          post :createItems           # POST /api/v1/items/createItems
          get :viewAllShopItems       # GET /api/v1/items/viewAllShopItems
        end
        member do
          get :viewShopItem           # GET /api/v1/items/:id/viewShopItem
          put :updateItem             # PUT /api/v1/items/:id/updateItem
          delete :deleteItem          # DELETE /api/v1/items/:id/deleteItem
          patch :mark_as_sold         # PATCH /api/v1/items/:id/mark_as_sold
         post :hold                   # Reserve item (e.g. during checkout) — POST /api/v1/items/:id/hold
         delete :release              # Release reserved item — DELETE /api/v1/items/:id/release
        end
      end

      # ================================
      # 🧾 Order & Payment routes
      # ================================
      resources :orders, only: [:create, :show] do
        member do
          patch :addresses                   # PATCH /api/v1/orders/:id/addresses
          post :cancel                      # POST /api/v1/orders/:id/cancel
          post :initiate_payment            # POST /api/v1/orders/:id/initiate_payment
          post :pay                         # POST /api/v1/orders/:id/pay
          post :dispatch                    # POST /api/v1/orders/:id/dispatch
          post :mark_delivered              # POST /api/v1/orders/:id/mark_delivered
          post :confirm_receipt             # POST /api/v1/orders/:id/confirm_receipt
          post :dispute                     # POST /api/v1/orders/:id/dispute
          post '/bank_webhooks/payment_received', to: 'bank_webhooks#payment_received' 
          # POST http://localhost:3000/api/v1/bank_webhooks/payment_received
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
          post :reactivate, on: :member                    # POST /api/v1/admin/users/:id/reactivate
        end

        # Admin Item Management
        resources :items, only: [] do
          collection do
            get :adminViewAllItems                         # GET /api/v1/admin/items/adminViewAllItems
          end
          member do
            delete :adminDeleteItem                        # DELETE /api/v1/admin/items/:id/adminDeleteItem
          end
        end

        # ================================
        # 🚚 Admin Order Management [NEW]
        # ================================
        resources :orders, only: [:index, :show] do       # GET /api/v1/admin/orders
          collection do
            get :bulk_index                                # GET /api/v1/admin/orders/bulk_index
          end
          member do
            patch :update_status                           # PATCH http://localhost:3000/api/v1/admin/orders/YOUR_ORDER_ID/update_status 
          end
        end
      end
    end
  end
end