# app/controllers/api/v1/provinces_controller.rb
module Api
  module V1
    class ProvincesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def index
        cache_key = "provinces_all"
        
        begin
          cached = Rails.cache.read(cache_key)
          
          if cached
            Rails.logger.info "📍 Serving provinces from CACHE"
            return render json: cached
          end
        rescue => e
          Rails.logger.warn "⚠️ Cache read failed: #{e.message}"
        end
        
        Rails.logger.info "📍 Cache MISS - loading provinces from database"
        provinces = Province.select(:id, :name).order(:name)
        
        begin
          Rails.cache.write(cache_key, provinces, expires_in: 1.day)
        rescue => e
          Rails.logger.warn "⚠️ Cache write failed: #{e.message}"
        end
        
        render json: provinces
      end
    end
  end
end