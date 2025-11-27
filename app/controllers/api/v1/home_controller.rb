module Api
  module V1
    class HomeController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def index
        home_data = {
          banners: get_banners,
          categories: get_categories,
          recent_items: get_recent_items,
          trending_near_you: get_trending_near_you,
          popular_schools: get_popular_schools,
          popular_brands: get_popular_brands,
          flash_sales: get_flash_sales,
          suggested_for_you: get_suggested_items
        }

        render json: home_data
      end

      private

      def get_banners
        Banner.active.ordered.limit(5)
      end

      def get_categories
        Category.where(parent_id: nil)
               .select(:id, :name, :parent_id)
               .limit(8)
      end

      def get_recent_items
        Item.where(deleted: false, status: 'active')
            .includes(:shop)
            .order(created_at: :desc)
            .limit(20)
      end

      def get_trending_near_you
        # Use a more reliable method for trending items
        Item.where(deleted: false, status: 'active')
            .includes(:shop)
            .order('RANDOM()')
            .limit(20)
      end

      def get_popular_schools
        # Check if association exists before using it
        if defined?(UserSchool) && School.reflect_on_association(:user_schools)
          School.joins(:user_schools)
                .group('schools.id')
                .order('COUNT(user_schools.id) DESC')
                .select(:id, :name)
                .limit(8)
        else
          School.select(:id, :name).limit(8)
        end
      end

      def get_popular_brands
        # Check if association exists
        if Brand.reflect_on_association(:items)
          Brand.joins(:items)
               .where(items: { deleted: false, status: 'active' })
               .group('brands.id')
               .order('COUNT(items.id) DESC')
               .select(:id, :name)
               .limit(8)
        else
          Brand.select(:id, :name).limit(8)
        end
      end

      def get_flash_sales
        # Fallback implementation
        Item.where(deleted: false, status: 'active')
            .where("label ILIKE ? OR name ILIKE ?", "%sale%", "%sale%")
            .includes(:shop)
            .limit(12)
      end

      def get_suggested_items
        Item.where(deleted: false, status: 'active')
            .includes(:shop)
            .order('RANDOM()')
            .limit(12)
      end
    end
  end
end