module Api
  module V1
    class SchoolsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def index
        # Start with base query - DON'T use town associations
        schools = School.all
        
        # Apply province filter - use direct province_id since schools table has it
        if params[:province_id].present?
          schools = schools.where(province_id: params[:province_id])
        end
        
        # Town filtering is NOT available since no town_id column
        # if params[:town_id].present? - SKIP THIS
        
        # Nearby filter - simplified without town joins
        if params[:nearby].present? && current_user&.location_id
          begin
            user_location = Location.find(current_user.location_id)
            if user_location.town_id
              # Use province_id from user's location if available
              schools = schools.where(province_id: user_location.town.province_id)
            end
          rescue => e
            Rails.logger.error "Nearby filter error: #{e.message}"
          end
        end
        
        # Search filter
        if params[:query].present?
          schools = schools.where('schools.name ILIKE ?', "%#{params[:query]}%")
        end

        # Get provinces for the schools
        province_ids = schools.pluck(:province_id).uniq
        provinces = Province.where(id: province_ids).index_by(&:id)

        # Build response
        response_data = schools.limit(50).map do |school|
          province = provinces[school.province_id]
          
          {
            id: school.id,
            name: school.name,
            province_id: school.province_id,
            province: province ? { id: province.id, name: province.name } : nil
            # No town data available since no town_id column
          }
        end

        render json: response_data
      end

      def show
        school = School.find(params[:id])
        province = Province.find_by(id: school.province_id)
        
        school_data = {
          id: school.id,
          name: school.name,
          province_id: school.province_id,
          province: province ? { id: province.id, name: province.name } : nil
        }

        school_info = {
          school: school_data,
          top_categories: get_school_top_categories(school.id),
          trending_items: get_school_trending_items(school.id),
          stats: {
            total_items: get_school_items_count(school.id),
            active_sellers: get_active_sellers_count(school.id)
          }
        }
        
        render json: school_info
      end

      def items
        school = School.find(params[:id])
        items = Item.joins(:user)
                   .joins('INNER JOIN user_schools ON users.id = user_schools.user_id')
                   .where(user_schools: { school_id: school.id }, 
                          items: { deleted: false, status: 'active' })
                   .includes(:shop, :item_images, :brand, :item_type)
                   .order(created_at: :desc)

        # Apply filters
        items = items.where(item_type_id: params[:category_id]) if params[:category_id]
        items = items.where(brand_id: params[:brand_id]) if params[:brand_id]
        items = items.where('price <= ?', params[:max_price]) if params[:max_price]

        render json: items.paginate(page: params[:page], per_page: 20)
      end

      private

      def get_school_top_categories(school_id)
        ItemType.joins(items: [:user])
                .joins('INNER JOIN user_schools ON users.id = user_schools.user_id')
                .where(user_schools: { school_id: school_id }, 
                       items: { deleted: false, status: 'active' })
                .group('item_types.id')
                .order('COUNT(items.id) DESC')
                .select('item_types.id, item_types.name, COUNT(items.id) as items_count')
                .limit(5)
      end

      def get_school_trending_items(school_id)
        Item.joins(:user, :order_items)
            .joins('INNER JOIN user_schools ON users.id = user_schools.user_id')
            .where(user_schools: { school_id: school_id }, 
                   items: { deleted: false, status: 'active' })
            .group('items.id')
            .order('COUNT(order_items.id) DESC')
            .includes(:shop, :item_images)
            .limit(8)
      end

      def get_school_items_count(school_id)
        Item.joins(:user)
            .joins('INNER JOIN user_schools ON users.id = user_schools.user_id')
            .where(user_schools: { school_id: school_id }, 
                   items: { deleted: false, status: 'active' })
            .count
      end

      def get_active_sellers_count(school_id)
        User.joins(:user_schools)
            .where(user_schools: { school_id: school_id })
            .joins(:items)
            .where(items: { deleted: false, status: 'active' })
            .distinct
            .count
      end
    end
  end
end