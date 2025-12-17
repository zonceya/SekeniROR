module Api
  module V1    
    class ItemsController < ApplicationController
      include Authenticatable  # Add this for user authentication
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      # GET /api/v1/items - Public listing of all active items
      def index
        items = Item.where(deleted: false, status: 'active')
        
        # Apply sorting
        if params[:sort] == 'newest'
          items = items.order(created_at: :desc)
        end
        
        # Apply limit
        items = items.limit(params[:limit]) if params[:limit]
        
        # Include shop details for public viewing
        render json: items.includes(:shop).as_json(include: {
          shop: {
            only: [:id, :name, :display_name],
            include: {
              user: {
                only: [:id, :name]
              }
            }
          }
        })
      end

      # POST /api/v1/items - Add item to current user's shop
         def createItems
        # Get current user's shop
        shop = @current_user.shop
        
        if shop.nil?
          return render json: { error: "You need to have a shop to create items" }, status: :unprocessable_entity
        end
        
        # Create item for this shop
        item = shop.items.new(item_params.except(:tag_ids, :images))
        
        if item.save
          # Handle tags
          item_params[:tag_ids]&.each { |tag_id| item.item_tags.create!(tag_id: tag_id) }
          
          # Handle image uploads (multiple images)
          if params[:item][:images].present?
            image_upload_results = ImageUploadService.upload_item_images(
              item, 
              params[:item][:images]
            )
            
            # Log any upload failures
            failed_uploads = image_upload_results.select { |r| !r[:success] }
            if failed_uploads.any?
              Rails.logger.warn "Some item images failed to upload for item #{item.id}: #{failed_uploads.map { |f| f[:error] }}"
            end
          end
          
          # Generate image URLs for response
          image_urls = item.images.attached? ? generate_item_image_urls(item) : []
          
          render json: {
            success: true,
            item: item.as_json(include: {
              shop: { only: [:id, :name] }
            }),
            images: image_urls,
            message: "Item created successfully"
          }, status: :created
        else
          render json: { 
            success: false,
            errors: item.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
   def add_images
        item = Item.find_by(id: params[:id], deleted: false)
        
        if item.nil?
          return render json: { error: "Item not found" }, status: :not_found
        end
        
        # Ensure user owns the item
        if item.shop.user_id != @current_user.id
          return render json: { error: "Not authorized" }, status: :unauthorized
        end
        
        unless params[:images].present?
          return render json: { error: "No images provided" }, status: :unprocessable_entity
        end
        
        # Upload new images
        image_upload_results = ImageUploadService.upload_item_images(
          item, 
          params[:images]
        )
        
        successful_uploads = image_upload_results.select { |r| r[:success] }
        failed_uploads = image_upload_results.select { |r| !r[:success] }
        
        # Generate updated image URLs
        image_urls = item.reload.images.attached? ? generate_item_image_urls(item) : []
        
        render json: {
          success: true,
          message: "Images added successfully",
          uploaded_count: successful_uploads.count,
          failed_count: failed_uploads.count,
          failed_uploads: failed_uploads.map { |f| f[:error] },
          total_images: item.images.count,
          images: image_urls
        }, status: :ok
      end
         def remove_image
        item = Item.find_by(id: params[:id], deleted: false)
        
        if item.nil?
          return render json: { error: "Item not found" }, status: :not_found
        end
        
        # Ensure user owns the item
        if item.shop.user_id != @current_user.id
          return render json: { error: "Not authorized" }, status: :unauthorized
        end
        
        # Find the specific image attachment
        image_attachment = item.images.find_by(id: params[:image_id])
        
        if image_attachment.nil?
          return render json: { error: "Image not found" }, status: :not_found
        end
        
        # Purge the image
        image_attachment.purge
        
        # Clear cache for this item's images
        ImageUploadService.clear_record_image_cache(item, :images)
        
        render json: {
          success: true,
          message: "Image removed successfully",
          remaining_images: item.reload.images.count
        }, status: :ok
      end
      # GET /api/v1/shops/:shop_id/items - Public view of a specific shop's items
      def shop_items
        shop = Shop.find_by(id: params[:shop_id])
        
        if shop.nil?
          return render json: { error: "Shop not found" }, status: :not_found
        end
        
        items = shop.items.where(deleted: false, status: 'active')
        
        # Apply filters
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

      # GET /api/v1/items/:id - Public view of specific item
      def show
        item = Item.includes(:shop).find_by(id: params[:id], deleted: false)
        
        if item.nil?
          return render json: { error: "Item not found" }, status: :not_found
        end
        
        render json: {
          success: true,
          item: item.as_json(include: {
            shop: {
              only: [:id, :name, :display_name],
              include: {
                user: {
                  only: [:id, :name]
                }
              }
            }
          })
        }
      end

      # GET /api/v1/my-shop/items - Get current user's shop items (private)
      def my_shop_items
        shop = @current_user.shop
        
        if shop.nil?
          return render json: { error: "You don't have a shop" }, status: :not_found
        end
        
        items = shop.items.where(deleted: false)
        
        render json: {
          success: true,
          shop: {
            id: shop.id,
            name: shop.name,
            display_name: shop.display_name
          },
          items: items
        }
      end

      def viewAllShopItems
        items = Item.where(deleted: false)
        render json: items
      end

      def viewShopItem
        render json: @item
      end

      def updateItem
        # Ensure user owns the item they're trying to update
        if @item.shop.user_id != @current_user.id
          return render json: { error: "Not authorized" }, status: :unauthorized
        end
        
        if @item.update(item_params)
          render json: @item
        else
          render json: @item.errors, status: :unprocessable_entity
        end
      end

      def deleteItem
        # Ensure user owns the item they're trying to delete
        if @item.shop.user_id != @current_user.id
          return render json: { error: "Not authorized" }, status: :unauthorized
        end
        
        if @item.update(deleted: true)
          render json: { message: 'Item soft-deleted' }, status: :ok
        else
          render json: @item.errors, status: :unprocessable_entity
        end
      end

      def mark_as_sold
        # Ensure user owns the item
        if @item.shop.user_id != @current_user.id
          return render json: { error: "Not authorized" }, status: :unauthorized
        end
        
        if @item.update(status: :sold)
          render json: @item
        else
          render json: @item.errors, status: :unprocessable_entity
        end
      end

      def reserve_item
        item = Item.find(params[:id])
        
        # Check if item is active and not deleted
        if item.deleted? || item.status != 'active'
          return render json: { error: "Item is not available for reservation" }, status: :unprocessable_entity
        end
        
        if item.reserved < item.quantity
          item.increment!(:reserved)
          render json: { message: 'Item reserved' }, status: :ok
        else
          render json: { error: "Item is fully reserved" }, status: :unprocessable_entity
        end
      end

      private

          def set_item
        @item = Item.find_by(id: params[:id], deleted: false)
        render json: { error: "Item not found" }, status: :not_found unless @item
      end

      def item_params
        params.require(:item).permit(
          :name, :description, :item_type_id,
          :brand_id, :price, :quantity, :item_condition_id,
          :province_id, :location_id, :gender_id,
          :school_id, :size_id, :label, :status,
          :images, # Allow images parameter
          meta: [:color, :size], tag_ids: []
        )
      end
      def generate_item_image_urls(item)
            return [] unless item.images.attached?
            
            s3_client = Aws::S3::Client.new(
              access_key_id: ENV['R2_ACCESS_KEY_ID'],
              secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
              endpoint: ENV['R2_ENDPOINT'],
              region: 'auto',
              force_path_style: true
            )
            
            signer = Aws::S3::Presigner.new(client: s3_client)
            
            item.images.map do |image|
              begin
                {
                  id: image.id,
                  url: signer.presigned_url(
                    :get_object,
                    bucket: ENV['R2_BUCKET_NAME'],
                    key: image.key,
                    expires_in: 3600
                  ),
                  filename: image.filename.to_s,
                  content_type: image.content_type,
                  created_at: image.created_at
                }
              rescue => e
                Rails.logger.error "Failed to generate URL for image #{image.id}: #{e.message}"
                nil
              end
            end.compact
          end
        end
      end

      def item_params
        params.require(:item).permit(
          :name, :description, :item_type_id,  # Removed :shop_id - automatically assigned
          :brand_id, :price, :quantity, :item_condition_id,
          :province_id, :location_id, :gender_id,
          :school_id, :size_id, :label, :status,
          meta: [:color, :size], tag_ids: []
        )
      end
    end
  end
end