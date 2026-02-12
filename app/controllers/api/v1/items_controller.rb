module Api
  module V1    
    class ItemsController < ApplicationController
      include Authenticatable
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      
      before_action :set_item, only: [
        :viewShopItem, :updateItem, :deleteItem, 
        :mark_as_sold, :add_images, :remove_image
      ]
      
      # GET /api/v1/items - Public listing of all active items
      def index
        items = Item.where(deleted: false, status: 'active')
        
        # Filter by category if provided
        if params[:main_category_id].present?
          items = items.where(main_category_id: params[:main_category_id])
        end
        
        if params[:sub_category_id].present?
          items = items.where(sub_category_id: params[:sub_category_id])
        end
        
        # Filter by other attributes
        items = items.where(gender_id: params[:gender_id]) if params[:gender_id].present?
        items = items.where(school_id: params[:school_id]) if params[:school_id].present?
        items = items.where(size_id: params[:size_id]) if params[:size_id].present?
        items = items.where(color_id: params[:color_id]) if params[:color_id].present?
        items = items.where(province_id: params[:province_id]) if params[:province_id].present?
        items = items.where(location_id: params[:town_id]) if params[:town_id].present?
        items = items.where(brand_id: params[:brand_id]) if params[:brand_id].present?
        
        # Apply sorting
        if params[:sort] == 'newest'
          items = items.order(created_at: :desc)
        elsif params[:sort] == 'price_low'
          items = items.order(price: :asc)
        elsif params[:sort] == 'price_high'
          items = items.order(price: :desc)
        else
          items = items.order(created_at: :desc) # Default sort
        end
        
        # Apply pagination/limit
        items = items.limit(params[:limit]) if params[:limit]
        items = items.offset(params[:offset]) if params[:offset]
        
        # Include shop and category details for public viewing
        items_with_details = items.includes(:shop, :main_category, :sub_category, :gender, 
                                           :school, :size, :color, :province, :location, :brand).map do |item|
          {
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price.to_f,
            quantity: item.quantity,
            available_quantity: item.available_quantity,
            status: item.status,
            main_category: item.main_category&.name,
            main_category_id: item.main_category_id,
            sub_category: item.sub_category&.name,
            sub_category_id: item.sub_category_id,
            gender: item.gender&.name,
            gender_id: item.gender_id,
            school: item.school&.name,
            school_id: item.school_id,
            size: item.size&.name,
            size_id: item.size_id,
            color: item.color&.name,
            color_id: item.color_id,
            brand: item.brand&.name,
            brand_id: item.brand_id,
            condition: item.item_condition&.name,
            condition_id: item.item_condition_id,
            province: item.province&.name,
            province_id: item.province_id,
            town: item.location&.name,
            town_id: item.location_id,
            created_at: item.created_at,
            updated_at: item.updated_at,
            shop: {
              id: item.shop&.id,
              name: item.shop&.name,
              display_name: item.shop&.display_name,
              seller_name: item.shop&.user&.name
            },
            images: item.images.attached? ? generate_item_image_urls(item) : [],
            tags: item.tags.pluck(:name)
          }
        end
        
        render json: {
          success: true,
          items: items_with_details,
          total_count: items.count,
          filters_applied: {
            main_category_id: params[:main_category_id],
            sub_category_id: params[:sub_category_id],
            gender_id: params[:gender_id],
            school_id: params[:school_id],
            size_id: params[:size_id],
            color_id: params[:color_id],
            province_id: params[:province_id],
            town_id: params[:town_id],
            brand_id: params[:brand_id]
          }.compact
        }
      end

      # POST /api/v1/items - Add item to current user's shop
def createItems
  Rails.logger.info "Creating item for user #{@current_user.id}, shop: #{@current_user.shop&.id}"
  
  shop = @current_user.shop
  
  if shop.nil?
    Rails.logger.error "User #{@current_user.id} has no shop"
    return render json: { 
      success: false,
      error: "You need to have a shop to create items" 
    }, status: :unprocessable_entity
  end
  
  # Log received parameters
  Rails.logger.info "Item params: #{params[:item].inspect}"
  
  # Validate required fields for ITEM (not variant)
  required_fields = [:name, :description, :main_category_id, :sub_category_id]
  missing_fields = required_fields.select { |field| params[:item][field].blank? }
  
  if missing_fields.any?
    Rails.logger.error "Missing fields: #{missing_fields}"
    return render json: { 
      success: false,
      error: "Missing required fields: #{missing_fields.join(', ')}"
    }, status: :unprocessable_entity
  end
  
  # Validate main_category exists
  main_category = MainCategory.find_by(id: params[:item][:main_category_id])
  unless main_category
    Rails.logger.error "Invalid main_category_id: #{params[:item][:main_category_id]}"
    return render json: { 
      success: false,
      error: "Invalid main category",
      available_categories: MainCategory.active.pluck(:id, :name)
    }, status: :unprocessable_entity
  end
  
  # Validate sub_category exists and belongs to main_category
  sub_category = SubCategory.find_by(id: params[:item][:sub_category_id])
  unless sub_category
    Rails.logger.error "Invalid sub_category_id: #{params[:item][:sub_category_id]}"
    return render json: { 
      success: false,
      error: "Invalid sub category",
      available_sub_categories: main_category.sub_categories.active.pluck(:id, :name)
    }, status: :unprocessable_entity
  end
  
  if sub_category.main_category_id != main_category.id
    Rails.logger.error "Sub category #{sub_category.id} doesn't belong to main category #{main_category.id}"
    return render json: { 
      success: false,
      error: "Sub category must belong to the selected main category"
    }, status: :unprocessable_entity
  end
  
  begin
    # Extract variant-specific parameters
    variant_params = {
      size_id: params[:item][:size_id],
      color_id: params[:item][:color_id],
      condition_id: params[:item][:item_condition_id],
      price: params[:item][:price],
      quantity: params[:item][:quantity]
    }
    
    # Build item with basic info (no variant-specific fields)
    item_params = item_params_for_create.to_h
    
    # Remove variant-specific fields from item params
    item_params = item_params.except(:size_id, :color_id, :item_condition_id, :price, :quantity)
    
    # Set total_quantity from variant quantity
    item_params[:total_quantity] = variant_params[:quantity].to_i if variant_params[:quantity]
    
    item = shop.items.new(item_params)
    item.item_type_id = nil
    
    # Save the item
    if item.save
      Rails.logger.info "Item saved successfully: #{item.id}"
      
      # Create item variant if we have variant data
      if variant_params[:size_id].present? || variant_params[:color_id].present? || variant_params[:condition_id].present?
        begin
          item_variant = item.item_variants.create!(
            size_id: variant_params[:size_id],
            color_id: variant_params[:color_id],
            condition_id: variant_params[:condition_id],
            price: variant_params[:price],
            quantity: variant_params[:quantity] || 0,
            is_active: true
          )
          Rails.logger.info "Item variant created: #{item_variant.id}"
        rescue => e
          Rails.logger.error "Failed to create item variant: #{e.message}"
          # Don't fail the whole request if variant creation fails
        end
      end
      
      # Handle tags
      if params[:item][:tag_ids].present?
  # Remove duplicates from the incoming array
  unique_tag_ids = params[:item][:tag_ids].map(&:to_i).uniq
  
  unique_tag_ids.each do |tag_id|
    # Check if tag exists and if this item doesn't already have it
    if Tag.exists?(id: tag_id)
      unless item.item_tags.exists?(tag_id: tag_id)
        item.item_tags.create!(tag_id: tag_id)
        Rails.logger.info "✅ Added tag #{tag_id} to item #{item.id}"
      else
        Rails.logger.info "⏭️ Tag #{tag_id} already exists for item #{item.id}, skipping"
      end
    else
      Rails.logger.warn "⚠️ Tag ID #{tag_id} does not exist, skipping"
    end
  end
end
      
      # Handle images
      image_urls = []
      if params[:item] && params[:item][:images].present?
        begin
          image_upload_results = ImageUploadService.upload_item_images(
            item, 
            params[:item][:images]
          )
          
          successful_uploads = image_upload_results.select { |r| r[:success] }
          failed_uploads = image_upload_results.select { |r| !r[:success] }
          
          image_urls = generate_item_image_urls(item)
          
          if failed_uploads.any?
            Rails.logger.warn "Some images failed to upload for item #{item.id}: #{failed_uploads.map { |f| f[:error] }}"
          end
        rescue => e
          Rails.logger.error "Image upload error: #{e.message}"
        end
      end
      
      # Return success response with detailed item info
      render json: {
        success: true,
        message: "Item created successfully",
        item: {
          id: item.id,
          name: item.name,
          description: item.description,
          main_category_id: item.main_category_id,
          main_category_name: main_category.name,
          sub_category_id: item.sub_category_id,
          sub_category_name: sub_category.name,
          gender_id: item.gender_id,
          gender_name: item.gender&.name,
          school_id: item.school_id,
          school_name: item.school&.name,
          brand_id: item.brand_id,
          brand_name: item.brand&.name,
          province_id: item.province_id,
          province_name: item.province&.name,
          town_id: item.location_id,
          town_name: item.location&.state_or_region || item.location&.town&.name,
          shop_id: item.shop_id,
          shop_name: shop.name,
          created_at: item.created_at,
          updated_at: item.updated_at,
          tags: item.tags.pluck(:name),
          tag_ids: item.tags.pluck(:id)
        },
        variants: item.item_variants.map do |variant|
          {
            id: variant.id,
            size_id: variant.size_id,
            size_name: variant.size&.name,
            color_id: variant.color_id,
            color_name: variant.color&.name,
            condition_id: variant.condition_id,
            condition_name: variant.condition&.name,
            price: variant.price&.to_f,
            quantity: variant.quantity,
            sku: variant.sku
          }
        end,
        images: image_urls
      }, status: :created
      
    else
      Rails.logger.error "Item save failed: #{item.errors.full_messages}"
      render json: { 
        success: false,
        error: "Failed to create item",
        errors: item.errors.full_messages,
        details: item.errors.details
      }, status: :unprocessable_entity
    end
    
  rescue => e
    Rails.logger.error "Exception in createItems: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { 
      success: false,
      error: "Server error: #{e.message}",
      trace: Rails.env.development? ? e.backtrace : nil
    }, status: :internal_server_error
  end
end

# Separate params method for creating items (without variant-specific fields)
def item_params_for_create
  params.require(:item).permit(
    :name, :description, 
    :main_category_id, :sub_category_id,
    :gender_id, :school_id, :brand_id,
    :province_id, :location_id, :label, :status,
    :images,
    tag_ids: []
  )
end

# Keep existing item_params for updates
def item_params
  params.require(:item).permit(
    :name, :description, :price, :quantity,
    :size_id, :color_id, :item_condition_id,
    :main_category_id, :sub_category_id,
    :gender_id, :school_id, :brand_id, 
    :province_id, :location_id, :label, :status,
    :images,
    tag_ids: []
  )
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
        
        # Check image limit
        total_images = item.images.count + Array(params[:images]).count
        if total_images > 3
          return render json: { 
            error: "Cannot add images. Maximum 3 images allowed. Current: #{item.images.count}" 
          }, status: :unprocessable_entity
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
        items = items.where(main_category_id: params[:main_category_id]) if params[:main_category_id].present?
        items = items.where(sub_category_id: params[:sub_category_id]) if params[:sub_category_id].present?
        items = items.where(gender_id: params[:gender_id]) if params[:gender_id].present?
        
        if params[:sort] == 'newest'
          items = items.order(created_at: :desc)
        end
        
        items_with_images = items.map do |item|
          item_data = item.as_json
          item_data['images'] = item.images.attached? ? generate_item_image_urls(item) : []
          item_data
        end
        
        render json: {
          success: true,
          shop: {
            id: shop.id,
            name: shop.public_name,
            seller_name: shop.user.name
          },
          items: items_with_images
        }
      end

      # GET /api/v1/items/:id - Public view of specific item
      def show
        item = Item.includes(:shop, :main_category, :sub_category, :gender, 
                            :school, :size, :color, :province, :location, 
                            :brand, :item_condition, :tags).find_by(id: params[:id], deleted: false)
        
        if item.nil?
          return render json: { error: "Item not found" }, status: :not_found
        end
        
        render json: {
          success: true,
          item: {
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price.to_f,
            quantity: item.quantity,
            available_quantity: item.available_quantity,
            status: item.status,
            main_category: item.main_category&.as_json,
            sub_category: item.sub_category&.as_json,
            gender: item.gender&.as_json,
            school: item.school&.as_json,
            size: item.size&.as_json,
            color: item.color&.as_json,
            brand: item.brand&.as_json,
            condition: item.item_condition&.as_json,
            province: item.province&.as_json,
            town: item.location&.as_json,
            created_at: item.created_at,
            updated_at: item.updated_at,
            shop: {
              id: item.shop&.id,
              name: item.shop&.name,
              display_name: item.shop&.display_name,
              seller_name: item.shop&.user&.name
            },
            images: item.images.attached? ? generate_item_image_urls(item) : [],
            tags: item.tags.as_json
          }
        }
      end

      # GET /api/v1/my-shop/items - Get current user's shop items (private)
      def my_shop_items
        shop = @current_user.shop
        
        if shop.nil?
          return render json: { error: "You don't have a shop" }, status: :not_found
        end
        
        items = shop.items.where(deleted: false)
        
        # Apply filters
        items = items.where(main_category_id: params[:main_category_id]) if params[:main_category_id].present?
        items = items.where(sub_category_id: params[:sub_category_id]) if params[:sub_category_id].present?
        items = items.where(status: params[:status]) if params[:status].present?
        
        # Generate detailed info for each item
        items_with_details = items.map do |item|
          {
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price.to_f,
            quantity: item.quantity,
            available_quantity: item.available_quantity,
            status: item.status,
            main_category: item.main_category&.name,
            main_category_id: item.main_category_id,
            sub_category: item.sub_category&.name,
            sub_category_id: item.sub_category_id,
            gender: item.gender&.name,
            school: item.school&.name,
            size: item.size&.name,
            color: item.color&.name,
            brand: item.brand&.name,
            condition: item.item_condition&.name,
            province: item.province&.name,
            town: item.location&.name,
            created_at: item.created_at,
            updated_at: item.updated_at,
            images: item.images.attached? ? generate_item_image_urls(item) : [],
            tags: item.tags.pluck(:name)
          }
        end
        
        render json: {
          success: true,
          shop: {
            id: shop.id,
            name: shop.name,
            display_name: shop.display_name
          },
          items: items_with_details,
          stats: {
            total_items: items.count,
            active_items: items.where(status: 'active').count,
            sold_items: items.where(status: 'sold').count,
            inactive_items: items.where(status: 'inactive').count
          }
        }
      end

      def viewAllShopItems
        items = Item.where(deleted: false)
        render json: items
      end

      def viewShopItem
        render json: {
          success: true,
          item: @item.as_json(include: {
            shop: { only: [:id, :name] },
            main_category: { only: [:id, :name] },
            sub_category: { only: [:id, :name] },
            item_condition: { only: [:id, :name] },
            gender: { only: [:id, :name] },
            school: { only: [:id, :name] },
            size: { only: [:id, :name] },
            color: { only: [:id, :name] },
            province: { only: [:id, :name] },
            location: { only: [:id, :name] },
            brand: { only: [:id, :name] },
            tags: { only: [:id, :name] }
          })
        }
      end

      def updateItem
        # Ensure user owns the item they're trying to update
        if @item.shop.user_id != @current_user.id
          return render json: { error: "Not authorized" }, status: :unauthorized
        end
        
        # Validate category consistency if categories are being updated
        if params[:item][:main_category_id].present? || params[:item][:sub_category_id].present?
          main_category_id = params[:item][:main_category_id] || @item.main_category_id
          sub_category_id = params[:item][:sub_category_id] || @item.sub_category_id
          
          if sub_category_id.present?
            sub_category = SubCategory.find_by(id: sub_category_id)
            if sub_category && sub_category.main_category_id != main_category_id.to_i
              return render json: {
                success: false,
                error: "Sub category must belong to the selected main category"
              }, status: :unprocessable_entity
            end
          end
        end
        
        if @item.update(item_params)
          render json: {
            success: true,
            message: "Item updated successfully",
            item: @item.reload.as_json(include: {
              main_category: { only: [:id, :name] },
              sub_category: { only: [:id, :name] }
            })
          }
        else
          render json: {
            success: false,
            errors: @item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def deleteItem
        # Ensure user owns the item they're trying to delete
        if @item.shop.user_id != @current_user.id
          return render json: { 
            success: false,
            error: "Not authorized" 
          }, status: :unauthorized
        end
        
        if @item.update(deleted: true)
          render json: { 
            success: true,
            message: 'Item soft-deleted successfully' 
          }, status: :ok
        else
          render json: { 
            success: false,
            errors: @item.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end

      def mark_as_sold
        # Ensure user owns the item
        if @item.shop.user_id != @current_user.id
          return render json: { 
            success: false,
            error: "Not authorized" 
          }, status: :unauthorized
        end
        
        if @item.update(status: 'sold')
          render json: {
            success: true,
            message: "Item marked as sold",
            item: @item
          }
        else
          render json: { 
            success: false,
            errors: @item.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end

      def reserve_item
        item = Item.find(params[:id])
        
        # Check if item is active and not deleted
        if item.deleted? || item.status != 'active'
          return render json: { 
            success: false,
            error: "Item is not available for reservation" 
          }, status: :unprocessable_entity
        end
        
        if item.reserved < item.quantity
          item.increment!(:reserved)
          render json: { 
            success: true,
            message: 'Item reserved',
            available_quantity: item.available_quantity
          }, status: :ok
        else
          render json: { 
            success: false,
            error: "Item is fully reserved" 
          }, status: :unprocessable_entity
        end
      end
      
      def hold
        item = Item.find_by(id: params[:id], deleted: false)
        
        unless item
          return render json: { 
            success: false,
            error: "Item not found" 
          }, status: :not_found
        end
        
        if item.reserved < item.quantity
          item.increment!(:reserved)
          render json: { 
            success: true,
            message: 'Item placed on hold',
            reserved_count: item.reserved,
            available: item.available_quantity
          }
        else
          render json: { 
            success: false,
            error: "Item is fully reserved" 
          }, status: :unprocessable_entity
        end
      end
      
      def release
        item = Item.find_by(id: params[:id], deleted: false)
        
        unless item
          return render json: { 
            success: false,
            error: "Item not found" 
          }, status: :not_found
        end
        
        if item.reserved > 0
          item.decrement!(:reserved)
          render json: { 
            success: true,
            message: 'Item released from hold',
            reserved_count: item.reserved,
            available: item.available_quantity
          }
        else
          render json: { 
            success: false,
            error: "No reservations to release" 
          }, status: :unprocessable_entity
        end
      end

      private

      def set_item
        @item = Item.find_by(id: params[:id], deleted: false)
        unless @item
          render json: { 
            success: false,
            error: "Item not found" 
          }, status: :not_found
        end
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
end