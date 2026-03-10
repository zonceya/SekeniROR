# app/controllers/api/v1/recommendations_controller.rb
module Api
  module V1
    class RecommendationsController < ApplicationController
      include Authenticatable
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      before_action :set_user_context
      
      # GET /api/v1/recommendations/home
      def home
        school_id = @user_school_id
        
        if school_id.nil?
          return render json: {
            success: false,
            error: "Please select a school first",
            need_school_selection: true
          }
        end
        
        # 🟢 CHECK IF SCHOOL HAS ITEMS
        unless has_items_in_school?(school_id)
          nearby_schools = find_nearby_schools(school_id)
          
          if nearby_schools.any?
            return render json: {
              success: true,
              school_id: school_id,
              message: "No items at your school yet. Showing nearby schools.",
              sections: [
                {
                  title: "From Nearby Schools",
                  type: "nearby",
                  items: items_from_schools(nearby_schools)
                },
                {
                  title: "Nearby School Essentials",
                  type: "nearby_essentials",
                  sections: school_essentials_from_schools(nearby_schools)
                },
                {
                  title: "Trending Near You",
                  type: "nearby_trending",
                  items: trending_from_schools(nearby_schools)
                }
              ]
            }
          else
            return render json: {
              success: true,
              school_id: school_id,
              message: "No items in your area yet",
              sections: [
                {
                  title: "Popular in South Africa",
                  type: "national",
                  items: national_popular_items
                }
              ]
            }
          end
        end
        
        # Try cache first
        cache_key = "school:#{school_id}:home:#{@current_user&.id}"
        cached = $redis.get(cache_key)
        
        if cached
          return render json: JSON.parse(cached)
        end
        
        # Build home feed
        feed = {
          success: true,
          school_id: school_id,
          sections: [
            {
              title: "Recommended For You",
              type: "recommended",
              items: recommended_items(school_id)
            },
            {
              title: "School Essentials",
              type: "essentials",
              sections: school_essentials(school_id)
            },
            {
              title: "Trending at Your School",
              type: "trending",
              items: trending_items(school_id)
            },
            {
              title: "Recently Added",
              type: "recent",
              items: recent_items(school_id)
            }
          ]
        }
        
        # Cache for 1 hour
        $redis.setex(cache_key, 3600, feed.to_json)
        
        render json: feed
      end
      
      # GET /api/v1/recommendations/uniform
      def uniform
        school_id = params[:school_id] || @user_school_id
        gender = params[:gender]
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        # 🟢 CHECK IF SCHOOL HAS UNIFORMS
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
        has_uniforms = Item.where(school_id: school_id, main_category_id: uniform_cat)
                          .where(deleted: false, status: 'active')
                          .exists?
        
        unless has_uniforms
          nearby_schools = find_nearby_schools(school_id)
          
          if nearby_schools.any?
            return render json: {
              success: true,
              school_id: school_id,
              message: "No uniforms at your school. Showing nearby schools.",
              sections: [
                {
                  title: "Uniforms From Nearby Schools",
                  type: "nearby_uniforms",
                  items: items_from_schools(nearby_schools, "uniform")
                }
              ]
            }
          end
        end
        
        # Base query
        items = Item.where(school_id: school_id)
                    .where(main_category_id: uniform_cat)
                    .where(deleted: false, status: 'active')
        
        # Apply gender filter if specified
        if gender.present? && gender != 'all'
          gender_id = Gender.find_by(name: gender.capitalize)&.id
          items = items.where(gender_id: gender_id) if gender_id
        end
        
        render json: {
          success: true,
          school_id: school_id,
          gender: gender || 'all',
          sections: [
            {
              title: "Summer Uniform",
              type: "summer",
              items: items.where("name ILIKE ? OR description ILIKE ?", "%summer%", "%summer%").limit(8)
            },
            {
              title: "Winter Uniform",
              type: "winter",
              items: items.where("name ILIKE ? OR description ILIKE ?", "%winter%", "%winter%").limit(8)
            },
            {
              title: "PE Kit",
              type: "pe_kit",
              items: items.where("name ILIKE ? OR description ILIKE ?", "%pe%", "%pe%").or(items.where("name ILIKE ?", "%sport%")).limit(8)
            },
            {
              title: "Accessories",
              type: "accessories",
              items: items.where("name ILIKE ? OR description ILIKE ?", "%tie%", "%tie%").or(items.where("name ILIKE ?", "%hat%")).or(items.where("name ILIKE ?", "%sock%")).limit(8)
            }
          ]
        }
      end
      
      # GET /api/v1/recommendations/sport
      def sport
        school_id = params[:school_id] || @user_school_id
        sport_type = params[:sport_type]
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        # 🟢 CHECK IF SCHOOL HAS SPORTS ITEMS
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        has_sports = Item.where(school_id: school_id, main_category_id: sport_cat)
                        .where(deleted: false, status: 'active')
                        .exists?
        
        unless has_sports
          nearby_schools = find_nearby_schools(school_id)
          
          if nearby_schools.any?
            return render json: {
              success: true,
              school_id: school_id,
              message: "No sports items at your school. Showing nearby schools.",
              sections: [
                {
                  title: "Sports From Nearby Schools",
                  type: "nearby_sports",
                  items: items_from_schools(nearby_schools, "sport")
                }
              ]
            }
          end
        end
        
        # Base query
        items = Item.where(school_id: school_id)
                    .where(main_category_id: sport_cat)
                    .where(deleted: false, status: 'active')
        
        # Define South African sports
        sports = ['rugby', 'cricket', 'hockey', 'netball', 'soccer']
        
        sections = sports.map do |sport|
          {
            title: sport.capitalize,
            type: sport,
            items: items.where("name ILIKE ? OR description ILIKE ?", "%#{sport}%", "%#{sport}%").limit(8)
          }
        end
        
        render json: {
          success: true,
          school_id: school_id,
          sections: sections
        }
      end
      
      # GET /api/v1/recommendations/recent
      def recent
        school_id = params[:school_id] || @user_school_id
        period = params[:period]
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        # 🟢 CHECK IF SCHOOL HAS ITEMS
        unless has_items_in_school?(school_id)
          nearby_schools = find_nearby_schools(school_id)
          
          if nearby_schools.any?
            return render json: {
              success: true,
              school_id: school_id,
              message: "No recent items at your school. Showing nearby.",
              sections: [
                {
                  title: "Recent From Nearby Schools",
                  type: "nearby_recent",
                  items: items_from_schools(nearby_schools, "recent")
                }
              ]
            }
          end
        end
        
        items = Item.where(school_id: school_id)
                    .where(deleted: false, status: 'active')
        
        case period
        when 'today'
          items = items.where('created_at > ?', Time.now.beginning_of_day)
          title = "Added Today"
        when 'yesterday'
          items = items.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day)
          title = "Added Yesterday"
        when 'week'
          items = items.where('created_at > ?', 7.days.ago)
          title = "Added This Week"
        else
          return render json: {
            success: true,
            school_id: school_id,
            sections: [
              {
                title: "Today",
                period: "today",
                items: items.where('created_at > ?', Time.now.beginning_of_day).limit(10)
              },
              {
                title: "Yesterday",
                period: "yesterday",
                items: items.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).limit(10)
              },
              {
                title: "Earlier This Week",
                period: "week",
                items: items.where('created_at > ?', 7.days.ago).where('created_at < ?', 1.day.ago.beginning_of_day).limit(10)
              }
            ]
          }
        end
        
        render json: {
          success: true,
          school_id: school_id,
          title: title,
          period: period,
          items: items.limit(30).order(created_at: :desc)
        }
      end
      
      # POST /api/v1/recommendations/track_view
      def track_view
  item_id = params[:item_id]
  source = params[:source]
  
  unless item_id
    return render json: { success: false, error: "Item ID required" }, status: :bad_request
  end
  
  school_id = @user_school_id || params[:school_id]
  
  # Save to database
  UserItemView.track(
    @current_user&.id,
    item_id,
    school_id,
    source,
    session.id
  )
  
  # 🟢 FIX: Try Redis, but don't crash if it's missing
  begin
    if school_id && defined?($redis) && $redis
      $redis.zincrby("school:#{school_id}:trending:today", 1, item_id)
      $redis.zincrby("school:#{school_id}:trending:week", 1, item_id)
      
      if @current_user && school_id
        $redis.del("school:#{school_id}:home:#{@current_user.id}")
      end
    end
  rescue => e
    # Log but don't fail the request
    Rails.logger.error "Redis error (non-fatal): #{e.message}"
  end
  
  render json: { success: true, message: "View tracked" }
end
      
      # POST /api/v1/recommendations/track_click
      def track_click
        item_id = params[:item_id]
        source = params[:source]
        position = params[:position]
        
        if item_id
          school_id = @user_school_id || params[:school_id]
          
          if school_id
            $redis.zincrby("school:#{school_id}:clicks:#{Date.today}", 1, item_id)
          end
        end
        
        render json: { success: true }
      end
      
      private
      
      def set_user_context
        @user_school_id = nil
        
        if @current_user
          user_school = UserSchool.where(user_id: @current_user.id)
                                  .order(created_at: :desc)
                                  .first
          @user_school_id = user_school&.school_id
        end
      end
      
      # 🟢 HELPER METHODS - All in one place
      
      def find_nearby_schools(school_id)
        school = School.find_by(id: school_id)
        return [] unless school
        
        nearby_ids = School.where(province_id: school.province_id)
                          .where.not(id: school_id)
                          .limit(10)
                          .pluck(:id)
        
        if nearby_ids.empty? && school.location_id
          nearby_ids = School.where(location_id: school.location_id)
                            .where.not(id: school_id)
                            .limit(10)
                            .pluck(:id)
        end
        
        nearby_ids
      end
      
      def has_items_in_school?(school_id)
        Item.where(school_id: school_id, deleted: false, status: 'active').exists?
      end
      
      # 🟢 NEW - Missing method!
      def items_from_schools(school_ids, type = "general")
        items = Item.where(school_id: school_ids)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .limit(20)
        
        format_items(items, "From nearby schools")
      end
      
      def school_essentials_from_schools(school_ids)
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear']).pluck(:id)
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        accessory_cat = MainCategory.where(name: ['Accessories']).pluck(:id)
        
        {
          uniforms: format_items(
            Item.where(school_id: school_ids, main_category_id: uniform_cat)
                .where(deleted: false, status: 'active')
                .order(created_at: :desc)
                .limit(6),
            "Nearby School Uniforms"
          ),
          sports: format_items(
            Item.where(school_id: school_ids, main_category_id: sport_cat)
                .where(deleted: false, status: 'active')
                .order(created_at: :desc)
                .limit(6),
            "Nearby Sports Gear"
          ),
          accessories: format_items(
            Item.where(school_id: school_ids, main_category_id: accessory_cat)
                .where(deleted: false, status: 'active')
                .order(created_at: :desc)
                .limit(6),
            "Nearby Accessories"
          )
        }
      end
      
      def trending_from_schools(school_ids)
        item_ids = UserItemView.where(school_id: school_ids)
                              .where('created_at > ?', 2.days.ago)
                              .group(:item_id)
                              .order('SUM(view_count) DESC')
                              .limit(20)
                              .pluck(:item_id)
        
        items = Item.where(id: item_ids).where(deleted: false, status: 'active')
        format_items(items, "Trending near you")
      end
      
      def national_popular_items
        items = Item.where(deleted: false, status: 'active')
                    .left_joins(:user_item_views)
                    .group(:id)
                    .order('COUNT(user_item_views.id) DESC, items.created_at DESC')
                    .limit(20)
        
        format_items(items, "Popular in South Africa")
      end
      
      def recommended_items(school_id)
        return popular_in_school(school_id) unless @current_user
        
        preferred_categories = UserItemView.user_preferred_categories(@current_user.id)
        
        viewed_ids = UserItemView.where(user_id: @current_user.id)
                                 .recent
                                 .pluck(:item_id)
        
        favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
        purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
        
        excluded_ids = (viewed_ids + favorited_ids + purchased_ids).uniq.first(50)
        
        if preferred_categories.any?
          items = Item.where(school_id: school_id)
                      .where(main_category_id: preferred_categories)
                      .where(deleted: false, status: 'active')
                      .where.not(id: excluded_ids)
                      .order(created_at: :desc)
                      .limit(12)
          
          return format_items(items, "Based on your interests") if items.count >= 6
        end
        
        popular_in_school(school_id)
      end
      
      def popular_in_school(school_id)
  # Get popular items from views (using model - already fixed)
  popular_ids = UserItemView.popular_in_school(school_id, 20)
  
  # Supplement with favorites - FIXED with Arel.sql
  favorite_ids = Favorite.joins(:item)
                        .where(items: { school_id: school_id })
                        .group(:item_id)
                        .order(Arel.sql('COUNT(*) DESC'))
                        .limit(10)
                        .pluck(:item_id)
  
  # Supplement with purchases - FIXED with Arel.sql
  purchase_ids = PurchaseHistory.joins(:item)
                               .where(items: { school_id: school_id })
                               .group(:item_id)
                               .order(Arel.sql('COUNT(*) DESC'))
                               .limit(10)
                               .pluck(:item_id)
  
  all_popular_ids = (popular_ids + favorite_ids + purchase_ids).uniq.first(20)
  
  items = Item.where(id: all_popular_ids)
              .where(deleted: false, status: 'active')
  
  format_items(items, "Popular at your school")
end
      
      def school_essentials(school_id)
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear']).pluck(:id)
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        accessory_cat = MainCategory.where(name: ['Accessories']).pluck(:id)
        
        {
          uniforms: format_items(
            Item.where(school_id: school_id, main_category_id: uniform_cat)
                .where(deleted: false, status: 'active')
                .order(created_at: :desc)
                .limit(6),
            "School Uniforms"
          ),
          sports: format_items(
            Item.where(school_id: school_id, main_category_id: sport_cat)
                .where(deleted: false, status: 'active')
                .order(created_at: :desc)
                .limit(6),
            "Sports Gear"
          ),
          accessories: format_items(
            Item.where(school_id: school_id, main_category_id: accessory_cat)
                .where(deleted: false, status: 'active')
                .order(created_at: :desc)
                .limit(6),
            "Accessories"
          )
        }
      end
      
      def trending_items(school_id)
        trending_ids = $redis.zrevrange("school:#{school_id}:trending:today", 0, 14)
        
        if trending_ids.any?
          items = Item.where(id: trending_ids).where(deleted: false, status: 'active')
          return format_items(items, "Trending today") if items.any?
        end
        
        popular_ids = UserItemView.popular_in_school(school_id, 15, 2)
        items = Item.where(id: popular_ids).where(deleted: false, status: 'active')
        
        format_items(items, "Trending now")
      end
      
      def recent_items(school_id)
        items = Item.where(school_id: school_id)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .limit(10)
        
        format_items(items, "Just added")
      end
      
      def fallback_recommendations
        {
          sections: [
            {
              title: "Popular Items",
              type: "popular",
              items: format_items(Item.where(deleted: false, status: 'active').order(created_at: :desc).limit(10))
            }
          ]
        }
      end
      
      def format_items(items, reason = nil)
        items.map do |item|
          {
            id: item.id,
            name: item.name.truncate(50),
            description: item.description&.truncate(80),
            price: item.price.to_f,
            image: item.images.attached? ? generate_item_image_url(item) : nil,
            school_id: item.school_id,
            category: item.main_category&.name,
            gender: item.gender&.name,
            reason: reason,
            created_at: item.created_at
          }
        end
      end
      
      def generate_item_image_url(item)
        return nil unless item.images.attached?
        
        s3_client = Aws::S3::Client.new(
          access_key_id: ENV['R2_ACCESS_KEY_ID'],
          secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
          endpoint: ENV['R2_ENDPOINT'],
          region: 'auto',
          force_path_style: true
        )
        
        signer = Aws::S3::Presigner.new(client: s3_client)
        
        signer.presigned_url(
          :get_object,
          bucket: ENV['R2_BUCKET_NAME'],
          key: item.images.first.key,
          expires_in: 3600
        )
      rescue => e
        Rails.logger.error "Failed to generate image URL: #{e.message}"
        nil
      end
    end
  end
end