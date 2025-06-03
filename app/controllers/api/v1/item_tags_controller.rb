module Api
  module V1
    class ItemTagsController < ApplicationController
      def index
        if params[:item_id]
          item = Item.find_by(id: params[:item_id])
          if item
            render json: item.tags
          else
            render json: { error: "Item not found" }, status: :not_found
          end
        else
          render json: ItemTag.all
        end
      end
    end
  end
end
