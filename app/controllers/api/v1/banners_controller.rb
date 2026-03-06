# app/controllers/api/v1/banners_controller.rb
module Api
  module V1
    class BannersController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_request, raise: false
      skip_before_action :authenticate, raise: false
      skip_before_action :authorize_request, raise: false
      skip_before_action :authenticate_user!, raise: false
      
      def index
        banners = Banner.active.ordered.limit(5)
        render json: banners.map { |banner| banner_json(banner) }
      end

      def create
        banner = Banner.new(banner_params)
        banner.position = Banner.maximum(:position).to_i + 1
        banner.active = true
        
        if banner.save
          render json: { 
            message: "Banner created successfully", 
            banner: banner_json(banner) 
          }, status: :created
        else
          render json: { errors: banner.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end

      def update
        banner = Banner.find(params[:id])
        
        if banner.update(banner_params)
          render json: { 
            message: "Banner updated successfully", 
            banner: banner_json(banner) 
          }
        else
          render json: { errors: banner.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end

      def destroy
        banner = Banner.find(params[:id])
        banner.destroy
        render json: { message: "Banner deleted successfully" }
      end

      private

      def banner_params
        params.permit(:title, :description, :image_url, :thumbnail_url, :redirect_url, 
                      :banner_type, :target_id, :target_type, :position, :active, 
                      :start_date, :end_date)
      end

      def banner_json(banner)
        {
          id: banner.id,
          title: banner.title,
          description: banner.description,
          image_url: banner.image_url,
          thumbnail_url: banner.thumbnail_url,
          redirect_url: banner.redirect_url,
          banner_type: banner.banner_type,
          target_id: banner.target_id,
          target_type: banner.target_type,
          position: banner.position,
          active: banner.active,
          start_date: banner.start_date,
          end_date: banner.end_date,
          created_at: banner.created_at,
          updated_at: banner.updated_at
        }
      end
    end
  end
end