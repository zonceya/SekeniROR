# app/controllers/api/v1/sub_categories_controller.rb
module Api
  module V1
    class SubCategoriesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # GET /api/v1/sub_categories?main_category_id=1
      def index
        main_category_id = params[:main_category_id]
        
        if main_category_id.present?
          main_category = MainCategory.find_by(id: main_category_id, is_active: true)
          
          if main_category
            sub_categories = main_category.sub_categories.active.ordered
            
            render json: {
              success: true,
              sub_categories: sub_categories.map { |sub|
                {
                  id: sub.id,
                  name: sub.name,
                  description: sub.description,
                  display_order: sub.display_order,
                  main_category_id: sub.main_category_id
                }
              }
            }
          else
            render json: { success: false, error: "Main category not found" }, status: :not_found
          end
        else
          render json: { success: false, error: "main_category_id is required" }, status: :bad_request
        end
      end
    end
  end
end