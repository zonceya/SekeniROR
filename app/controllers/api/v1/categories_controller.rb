module Api
  module V1
    class CategoriesController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def index
        categories = Category.where(parent_id: nil)
                           .select(:id, :name, :parent_id)
        render json: categories
      end

      def items
        category = Category.find(params[:id])
        
        # Get all subcategory IDs including the main category
        category_ids = category.subcategories.pluck(:id) << category.id
        
        items = Item.joins(:item_type)
                   .where(item_types: { category_id: category_ids }, 
                          items: { deleted: false, status: 'active' })
                   .includes(:shop, :brand)
                   .order(created_at: :desc)

        render json: items.paginate(page: params[:page], per_page: 20)
      end
    end
  end
end