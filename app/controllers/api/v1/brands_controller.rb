module Api
  module V1
    class BrandsController < ApplicationController
      def index
        brands = Brand.all
        
        # Simple implementation without items association
        if params[:popular]
          brands = brands.limit(8) # Basic limit for "popular"
        end
        
        render json: brands.select(:id, :name)
      end
    end
  end
end