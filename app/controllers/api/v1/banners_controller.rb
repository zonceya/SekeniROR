module Api
  module V1
    class BannersController < ApplicationController
      before_action :authenticate_user!, only: [:create, :update, :destroy]
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def index
        banners = Banner.active.ordered
        
        # Filter by type if provided
        banners = banners.where(banner_type: params[:type]) if params[:type].present?
        
        # Limit for specific use cases
        banners = banners.limit(params[:limit]) if params[:limit].present?

        render json: banners
      end

      # Admin actions
      def create
        banner = Banner.new(banner_params)
        if banner.save
          render json: banner, status: :created
        else
          render json: { errors: banner.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        banner = Banner.find(params[:id])
        if banner.update(banner_params)
          render json: banner
        else
          render json: { errors: banner.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        banner = Banner.find(params[:id])
        banner.destroy
        head :no_content
      end

      private

      def banner_params
        params.require(:banner).permit(
          :title, :description, :image_url, :thumbnail_url, :redirect_url,
          :banner_type, :target_type, :target_id, :position, :active,
          :start_date, :end_date
        )
      end
    end
  end
end