module Api
    module V1
      class ShopsController < ApplicationController
        include Authenticatable 
  
        def show
          shop = @current_user.shop
  
          if shop
            # Cache in Redis
            redis.set("user_#{@current_user.id}_shop", shop.to_json)
  
            render json: shop, status: :ok
          else
            render json: { error: "Shop not found" }, status: :not_found
          end
        end
  
        private
  
        def redis
          @redis ||= Redis.new(host: 'localhost', port: 6379)
        end
      end
    end
  end
  