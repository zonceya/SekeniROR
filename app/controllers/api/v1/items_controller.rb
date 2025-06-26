module Api
  module V1    
    class ItemsController < ApplicationController
      # Proper CSRF exemption for API endpoints
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      before_action :set_item, only: [:viewShopItem, :updateItem, :deleteItem, :mark_as_sold]

      def createItems
        item = Item.new(item_params.except(:tag_ids))
        if item.save
          item_params[:tag_ids]&.each { |tag_id| item.item_tags.create!(tag_id: tag_id) }
          render json: item, status: :created
        else
          render json: item.errors, status: :unprocessable_entity
        end
      end

      def viewAllShopItems
        items = Item.where(deleted: false)
        render json: items
      end

      def viewShopItem
        render json: @item
      end

      def updateItem
        if @item.update(item_params)
          render json: @item
        else
          render json: @item.errors, status: :unprocessable_entity
        end
      end

      def deleteItem
        if @item.update(deleted: true)
          render json: { message: 'Item soft-deleted' }, status: :ok
        else
          render json: @item.errors, status: :unprocessable_entity
        end
      end

      def mark_as_sold
        if @item.update(status: :sold)
          render json: @item
        else
          render json: @item.errors, status: :unprocessable_entity
        end
      end

      # Moved this to a separate action since it was floating in the controller
      def reserve_item
        item = Item.find(params[:id])
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
          :shop_id, :name, :description, :item_type_id,
          :brand_id, :price, :quantity, :item_condition_id,
          :province_id, :location_id, :gender_id,
          :school_id, :size_id, :label, :status,
          meta: [:color, :size], tag_ids: []
        )
      end
    end
  end
end