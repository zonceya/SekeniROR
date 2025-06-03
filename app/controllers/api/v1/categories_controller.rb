module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        render json: Category.select(:id, :name, :parent_id)
      end
    end
  end
end