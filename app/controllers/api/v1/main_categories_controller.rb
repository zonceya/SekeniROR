# app/controllers/api/v1/main_categories_controller.rb
module Api
  module V1
    class MainCategoriesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # GET /api/v1/main_categories
      def index
        categories = MainCategory.active.ordered
        
        render json: {
          success: true,
          categories: categories.map { |cat|
            {
              id: cat.id,
              name: cat.name,
              description: cat.description,
              icon_name: cat.icon_name,
              display_order: cat.display_order,
              item_types: cat.item_types.active.map { |type|
                {
                  id: type.id,
                  name: type.name,
                  description: type.description,
                  group_id: type.group_id
                }
              }
            }
          }
        }
      end
      
      # GET /api/v1/main_categories/:id/sub_categories
      def sub_categories
        main_category = MainCategory.find_by(id: params[:id], is_active: true)
        
        unless main_category
          return render json: { 
            success: false, 
            error: "Category not found" 
          }, status: :not_found
        end
        
        sub_categories = main_category.sub_categories.active.ordered
        
        render json: {
          success: true,
          main_category: {
            id: main_category.id,
            name: main_category.name
          },
          sub_categories: sub_categories.map { |sub|
            {
              id: sub.id,
              name: sub.name,
              description: sub.description,
              display_order: sub.display_order
            }
          }
        }
      end
    end
  end
end