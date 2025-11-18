module Api
  module V1
    class ItemsController < ApplicationController
      def index
        items = Item.where(deleted: false, status: 'active')
        
        # Apply sorting
        if params[:sort] == 'newest'
          items = items.order(created_at: :desc)
        end
        
        # Apply limit
        items = items.limit(params[:limit]) if params[:limit]
        
        render json: items.includes(:shop).as_json(include: { shop: { only: [:id, :name] } })
      end
    end
  end
end