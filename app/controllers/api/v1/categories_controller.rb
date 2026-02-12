# app/controllers/api/v1/categories_controller.rb
module Api
  module V1
    class CategoriesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # GET /api/v1/categories
      def index
        categories = MainCategory.active.ordered.includes(:sub_categories)
        
        render json: {
          success: true,
          categories: categories.map { |cat|
            {
              id: cat.id,
              name: cat.name,
              
              description: cat.description,
              icon_name: cat.icon_name,
              sub_categories: cat.sub_categories.active.ordered.map { |sub|
                {
                  id: sub.id,
                  name: sub.name,
                  description: sub.description
                }
              },
              item_types: cat.item_types.active.map { |type|
                {
                  id: type.id,
                  name: type.name,
                  description: type.description
                }
              }
            }
          }
        }
      end
    end
  end
end