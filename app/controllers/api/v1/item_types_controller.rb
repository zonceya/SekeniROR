module Api
  module V1
    class ItemTypesController < BaseController
      before_action :authenticate_user!

      def index
        item_types = ItemType.all
        render json: {
          success: true,
          item_types: item_types
        }
      end

      def show
        item_type = ItemType.find(params[:id])
        render json: {
          success: true,
          item_type: item_type
        }
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Item type not found'
        }, status: :not_found
      end
    end
  end
end
