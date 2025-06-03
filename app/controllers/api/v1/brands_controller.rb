module Api
  module V1
    class BrandsController < ApplicationController
      def index
        render json: Brand.select(:id, :name)
      end
    end
  end
end