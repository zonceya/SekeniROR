module Api
  module V1
    class ShopsController < ApplicationController
      include Authenticatable
      skip_forgery_protection
      # GET /api/v1/shop - Get current user's shop
      def show
        shop = @current_user.shop
        
        if shop
          render json: {
            success: true,
            shop: {
              id: shop.id,
              name: shop.name,
              display_name: shop.display_name || "",
              # NO logo_url here - frontend uses user's profile_picture from login
              user_id: shop.user_id,
              seller_name: shop.user.name,
              created_at: shop.created_at,
              items_count: shop.items.where(deleted: false).count
            }
          }, status: :ok
        else
          render json: { 
            success: false, 
            error: "Shop not found" 
          }, status: :not_found
        end
      end
      
      # PATCH /api/v1/shop - Update shop display name only
      def update
        shop = @current_user.shop
        
        if shop.nil?
          return render json: { 
            success: false, 
            error: "Shop not found" 
          }, status: :not_found
        end
        
        if shop.update(shop_params)
          render json: {
            success: true,
            message: "Shop display name updated",
            shop: {
              id: shop.id,
              name: shop.name,
              display_name: shop.display_name || ""
            }
          }, status: :ok
        else
          render json: { 
            success: false,
            error: "Failed to update shop name",
            errors: shop.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
      # app/controllers/api/v1/shops_controller.rb
# Add this method to your ShopsController:

# GET /api/v1/shops/:id/items - Public shop items
    def items
      shop = Shop.find_by(id: params[:id])
      
      if shop.nil?
        return render json: { 
          success: false, 
          error: "Shop not found" 
        }, status: :not_found
      end
      
      items = shop.items.where(deleted: false, status: 'active')
      
      # Apply filters if needed
      if params[:sort] == 'newest'
        items = items.order(created_at: :desc)
      end
      
      render json: {
        success: true,
        shop: {
          id: shop.id,
          name: shop.public_name,
          seller_name: shop.user.name
        },
        items: items.as_json(include: {
          shop: {
            only: [:id, :name]
          }
        })
      }
    end
      # GET /api/v1/shops/:id - Public shop view
      def public_show
        shop = Shop.find_by(id: params[:id])
        
        if shop.nil?
          return render json: { 
            success: false, 
            error: "Shop not found" 
          }, status: :not_found
        end
        
        render json: {
          success: true,
          shop: {
            id: shop.id,
            name: shop.public_name,
            seller: {
              id: shop.user.id,
              name: shop.user.name
              # Frontend will fetch user profile separately if needed
            },
            stats: {
              total_items: shop.items.where(deleted: false).count,
              active_items: shop.items.where(deleted: false, status: 'active').count
            },
            created_at: shop.created_at
          }
        }, status: :ok
      end
      
      private
      
      def shop_params
        params.require(:shop).permit(:display_name)
      end
    end
  end
end