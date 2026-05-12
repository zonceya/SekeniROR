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
        
        # Try cache first
        cache_key = "school:#{school_id}:home:#{@current_user&.id}"
        cached = $redis.get(cache_key)
        
        if cached
          return render json: JSON.parse(cached)
        end
        
        # Get nearby schools once for fallbacks
        nearby_ids = find_nearby_schools(school_id)
        
        # Build home feed with per-category fallbacks
        feed = {
          success: true,
          school_id: school_id,
          sections: [
            {
              title: "Recommended For You",
              type: "recommended",
              items: recommended_items_with_fallback(school_id, nearby_ids)
            },
            {
              title: "School Essentials",
              type: "essentials",
              sections: school_essentials_with_fallback(school_id, nearby_ids)
            },
            {
              title: "Trending",
              type: "trending",
              items: trending_items_with_fallback(school_id, nearby_ids)
            },
            {
              title: "Recently Added",
              type: "recent",
              items: recent_items_with_fallback(school_id, nearby_ids)
            }
          ]
        }
        
        # Cache for 1 hour
        $redis.setex(cache_key, 3600, feed.to_json)
        
        render json: feed
      end
      
      def recommended_all
        school_id = params[:school_id] || @user_school_id
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        period = params[:period] || 'all'
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        if @current_user
          preferred_categories = UserItemView.user_preferred_categories(@current_user.id)
          
          viewed_ids = UserItemView.where(user_id: @current_user.id)
                                   .recent
                                   .pluck(:item_id)
          
          favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
          purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
          
          excluded_ids = (viewed_ids + favorited_ids + purchased_ids).uniq.first(50)
          
          if preferred_categories.any?
            # Get paginated items with time filter
            items = Item.where(school_id: school_id)
                        .where(main_category_id: preferred_categories)
                        .where(deleted: false, status: 'active')
                        .where.not(id: excluded_ids)
            
            items = apply_time_filter(items, period)
            items = items.order(created_at: :desc).page(page).per(per_page)
            
            if items.present?
              return render_paginated_items(items, "Recommended for you", page, per_page)
            elsif nearby_ids.any?
              items = Item.where(school_id: nearby_ids)
                         .where(main_category_id: preferred_categories)
                         .where(deleted: false, status: 'active')
                         .where.not(id: excluded_ids)
              
              items = apply_time_filter(items, period)
              items = items.order(created_at: :desc).page(page).per(per_page)
              
              if items.present?
                return render_paginated_items(items, "From nearby schools", page, per_page)
              end
            end
          end
        end
        
        # Fallback to popular
        items = popular_items_paginated(school_id, nearby_ids, page, per_page, period)
        render_paginated_items(items, "Popular items", page, per_page)
      end

      def essentials_all
        school_id = params[:school_id] || @user_school_id
        category = params[:category]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        category_map = {
          'uniforms' => MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id),
          'sports' => MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id),
          'accessories' => MainCategory.where(name: ['Accessories']).pluck(:id)
        }
        
        if category.present? && category_map[category].present?
          items = get_category_items_paginated(school_id, nearby_ids, category_map[category], page, per_page)
          title = "#{category.capitalize} Essentials"
          render_paginated_items(items, title, page, per_page)
        else
          all_items = []
          category_map.each do |cat_name, cat_ids|
            cat_items = get_category_items_paginated(school_id, nearby_ids, cat_ids, 1, 6)
            all_items << {
              title: "#{cat_name.capitalize}",
              category: cat_name,
              items: cat_items
            }
          end
          
          render json: {
            success: true,
            school_id: school_id,
            sections: all_items
          }
        end
      end

      def trending_all
        school_id = params[:school_id] || @user_school_id
        period = params[:period] || 'today'
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        redis_key = "school:#{school_id}:trending:#{period}"
        trending_ids = $redis.zrevrange(redis_key, 0, 99)
        
        if trending_ids.any?
          items = Item.where(id: trending_ids).where(deleted: false, status: 'active')
          items = apply_time_filter(items, period) if period != 'today'
          items = items.page(page).per(per_page)
          
          if items.present?
            return render_paginated_items(items, "Trending #{period}", page, per_page)
          end
        end
        
        case period
        when 'today' then days = 1
        when 'week' then days = 7
        when 'month' then days = 30
        else days = 1
        end
        
        popular_ids = UserItemView.popular_in_school(school_id, 50, days)
        
        items = Item.where(id: popular_ids).where(deleted: false, status: 'active')
        items = items.page(page).per(per_page)
        
        if items.present?
          render_paginated_items(items, "Trending #{period}", page, per_page)
        elsif nearby_ids.any?
          items = Item.where(school_id: nearby_ids).where(deleted: false, status: 'active')
          items = items.order(created_at: :desc).page(page).per(per_page)
          render_paginated_items(items, "Trending near you", page, per_page)
        else
          render json: {
            success: true,
            school_id: school_id,
            title: "Trending #{period}",
            items: [],
            page: page,
            per_page: per_page,
            total_pages: 0
          }
        end
      end
      
      def recent_all
        school_id = params[:school_id] || @user_school_id
        period = params[:period]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        items = case period
        when 'today'
          get_recent_by_timeframe(school_id, nearby_ids, Time.now.beginning_of_day, nil)
        when 'yesterday'
          get_recent_by_timeframe(school_id, nearby_ids, 1.day.ago.beginning_of_day, 1.day.ago.end_of_day)
        when 'week'
          get_recent_by_timeframe(school_id, nearby_ids, 7.days.ago, nil)
        else
          get_recent_by_timeframe(school_id, nearby_ids, nil, nil)
        end
        
        items = items.page(page).per(per_page)
        
        title = case period
        when 'today' then "Added Today"
        when 'yesterday' then "Added Yesterday"
        when 'week' then "Added This Week"
        else "Recently Added"
        end
        
        render_paginated_items(items, title, page, per_page)
      end

      # GET /api/v1/recommendations/uniform
      def uniform
        school_id = params[:school_id] || @user_school_id
        gender = params[:gender]
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
        nearby_ids = find_nearby_schools(school_id)
        
        sections = build_uniform_sections(school_id, nearby_ids, uniform_cat, gender)
        
        render json: {
          success: true,
          school_id: school_id,
          gender: gender || 'all',
          sections: sections
        }
      end
      
      # GET /api/v1/recommendations/sport
      def sport
        school_id = params[:school_id] || @user_school_id
        sport_type = params[:sport_type]
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        nearby_ids = find_nearby_schools(school_id)
        
        sections = build_sport_sections(school_id, nearby_ids, sport_cat, sport_type)
        
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
        
        nearby_ids = find_nearby_schools(school_id)
        
        if period.present?
          items = get_recent_items_by_period(school_id, nearby_ids, period)
          title = period_title(period)
          
          render json: {
            success: true,
            school_id: school_id,
            title: title,
            period: period,
            items: items
          }
        else
          sections = [
            {
              title: "Today",
              period: "today",
              items: get_recent_items_by_period(school_id, nearby_ids, 'today')
            },
            {
              title: "Yesterday",
              period: "yesterday",
              items: get_recent_items_by_period(school_id, nearby_ids, 'yesterday')
            },
            {
              title: "Earlier This Week",
              period: "week",
              items: get_recent_items_by_period(school_id, nearby_ids, 'week')
            }
          ]
          
          render json: {
            success: true,
            school_id: school_id,
            sections: sections
          }
        end
      end
      
      # POST /api/v1/recommendations/track_view
      def track_view
        item_id = params[:item_id]
        source = params[:source]
        
        unless item_id
          return render json: { success: false, error: "Item ID required" }, status: :bad_request
        end
        
        school_id = @user_school_id || params[:school_id]
        
        UserItemView.track(
          @current_user&.id,
          item_id,
          school_id,
          source,
          session.id
        )
        
        begin
          if school_id && defined?($redis) && $redis
            $redis.zincrby("school:#{school_id}:trending:today", 1, item_id)
            $redis.zincrby("school:#{school_id}:trending:week", 1, item_id)
            
            if @current_user && school_id
              $redis.del("school:#{school_id}:home:#{@current_user.id}")
            end
          end
        rescue => e
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
      
      def find_nearby_schools(school_id)
        school = School.find_by(id: school_id)
        return [] unless school
        
        if school.location_id
          nearby = School.where(location_id: school.location_id)
                        .where.not(id: school_id)
                        .limit(10)
                        .pluck(:id)
          return nearby if nearby.any?
        end
        
        if school.province_id
          nearby = School.where(province_id: school.province_id)
                        .where.not(id: school_id)
                        .limit(10)
                        .pluck(:id)
          return nearby if nearby.any?
        end
        
        School.where.not(id: school_id).limit(10).pluck(:id)
      end
      
      def apply_time_filter(items, period)
        case period
        when 'today'
          items.where('created_at >= ?', Time.current.beginning_of_day)
        when 'week'
          items.where('created_at >= ?', 7.days.ago)
        when 'month'
          items.where('created_at >= ?', 30.days.ago)
        else
          items
        end
      end
      
      def recommended_items_with_fallback(school_id, nearby_ids)
        return popular_with_fallback(school_id, nearby_ids) unless @current_user
        
        preferred_categories = UserItemView.user_preferred_categories(@current_user.id)
        
        viewed_ids = UserItemView.where(user_id: @current_user.id).recent.pluck(:item_id)
        favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
        purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
        
        excluded_ids = (viewed_ids + favorited_ids + purchased_ids).compact.uniq.first(50)
        
        if preferred_categories.any?
          items = Item.where(school_id: school_id)
                      .where(main_category_id: preferred_categories)
                      .where(deleted: false, status: 'active')
                      .where.not(id: excluded_ids)
                      .order(created_at: :desc)
                      .limit(12)
                      .to_a
          
          if items.count >= 4
            return format_items(items, "Based on your interests")
          elsif nearby_ids.any?
            needed = 12 - items.count
            nearby_items = Item.where(school_id: nearby_ids)
                               .where(main_category_id: preferred_categories)
                               .where(deleted: false, status: 'active')
                               .where.not(id: excluded_ids)
                               .order(created_at: :desc)
                               .limit(needed)
                               .to_a
            
            all_items = items + nearby_items
            reason = items.any? ? "Recommended for you" : "From nearby schools"
            return format_items(all_items, reason) if all_items.any?
          end
        end
        
        popular_with_fallback(school_id, nearby_ids)
      end
      
      def popular_with_fallback(school_id, nearby_ids)
        popular_ids = UserItemView.popular_in_school(school_id, 20)
        favorite_ids = Favorite.joins(:item).where(items: { school_id: school_id }).group(:item_id).order(Arel.sql('COUNT(*) DESC')).limit(10).pluck(:item_id)
        purchase_ids = PurchaseHistory.joins(:item).where(items: { school_id: school_id }).group(:item_id).order(Arel.sql('COUNT(*) DESC')).limit(10).pluck(:item_id)
        
        all_popular_ids = (popular_ids + favorite_ids + purchase_ids).compact.uniq.first(20)
        
        if all_popular_ids.any?
          items = Item.where(id: all_popular_ids).where(deleted: false, status: 'active').limit(12).to_a
          return format_items(items, "Popular at your school") if items.any?
        end
        
        if nearby_ids.any?
          nearby_items = Item.where(school_id: nearby_ids).where(deleted: false, status: 'active').order(created_at: :desc).limit(12).to_a
          return format_items(nearby_items, "Popular near you") if nearby_items.any?
        end
        
        items = Item.where(school_id: school_id).where(deleted: false, status: 'active').order(created_at: :desc).limit(12).to_a
        format_items(items, "Items at your school")
      end
      
      def school_essentials_with_fallback(school_id, nearby_ids)
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        accessory_cat = MainCategory.where(name: ['Accessories']).pluck(:id)
        
        {
          uniforms: get_category_items(school_id, nearby_ids, uniform_cat, "Uniforms"),
          sports: get_category_items(school_id, nearby_ids, sport_cat, "Sports Gear"),
          accessories: get_category_items(school_id, nearby_ids, accessory_cat, "Accessories")
        }
      end
      
      def get_category_items(school_id, nearby_ids, category_ids, category_name)
        school_items = Item.where(school_id: school_id, main_category_id: category_ids)
                           .where(deleted: false, status: 'active')
                           .order(created_at: :desc)
                           .limit(6)
                           .to_a
        
        if school_items.any?
          format_items(school_items, "School #{category_name}")
        elsif nearby_ids.any?
          nearby_items = Item.where(school_id: nearby_ids, main_category_id: category_ids)
                             .where(deleted: false, status: 'active')
                             .order(created_at: :desc)
                             .limit(6)
                             .to_a
          format_items(nearby_items, "Nearby #{category_name}") if nearby_items.any?
        else
          []
        end
      end
      
      def trending_items_with_fallback(school_id, nearby_ids)
        trending_ids = $redis.zrevrange("school:#{school_id}:trending:today", 0, 14)
        
        if trending_ids.any?
          items = Item.where(id: trending_ids).where(deleted: false, status: 'active').to_a
          return format_items(items, "Trending today at your school") if items.any?
        end
        
        popular_ids = UserItemView.popular_in_school(school_id, 15, 2)
        items = Item.where(id: popular_ids).where(deleted: false, status: 'active').to_a
        
        if items.any?
          return format_items(items, "Trending at your school")
        elsif nearby_ids.any?
          nearby_items = Item.where(school_id: nearby_ids)
                             .where(deleted: false, status: 'active')
                             .order(created_at: :desc)
                             .limit(10)
                             .to_a
          return format_items(nearby_items, "Trending near you") if nearby_items.any?
        end
        
        items = Item.where(school_id: school_id)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .limit(12)
                    .to_a
        
        format_items(items, "Latest at your school")
      end
      
      def recent_items_with_fallback(school_id, nearby_ids)
        items = Item.where(school_id: school_id)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .limit(10)
                    .to_a
        
        if items.any?
          format_items(items, "Just added at your school")
        elsif nearby_ids.any?
          nearby_items = Item.where(school_id: nearby_ids)
                             .where(deleted: false, status: 'active')
                             .order(created_at: :desc)
                             .limit(10)
                             .to_a
          format_items(nearby_items, "Recent from nearby schools") if nearby_items.any?
        else
          []
        end
      end
      
      def get_recent_items_by_period(school_id, nearby_ids, period)
        case period
        when 'today'
          start_time = Time.now.beginning_of_day
        when 'yesterday'
          start_time = 1.day.ago.beginning_of_day
          end_time = 1.day.ago.end_of_day
        when 'week'
          start_time = 7.days.ago
        else
          return []
        end
        
        items = Item.where(school_id: school_id).where(deleted: false, status: 'active')
        
        if period == 'yesterday'
          items = items.where(created_at: start_time..end_time)
        else
          items = items.where('created_at > ?', start_time)
        end
        
        items = items.order(created_at: :desc).limit(10).to_a
        
        if items.any?
          format_items(items, period == 'today' ? "Added today at your school" : "Added #{period} at your school")
        elsif nearby_ids.any?
          nearby_items = Item.where(school_id: nearby_ids).where(deleted: false, status: 'active')
          
          if period == 'yesterday'
            nearby_items = nearby_items.where(created_at: start_time..end_time)
          else
            nearby_items = nearby_items.where('created_at > ?', start_time)
          end
          
          nearby_items = nearby_items.order(created_at: :desc).limit(10).to_a
          
          if nearby_items.any?
            format_items(nearby_items, period == 'today' ? "Added today near you" : "Added #{period} near you")
          else
            []
          end
        else
          []
        end
      end
      
      def period_title(period)
        case period
        when 'today' then "Added Today"
        when 'yesterday' then "Added Yesterday"
        when 'week' then "Added This Week"
        else "Recent Items"
        end
      end
      
      def popular_items_paginated(school_id, nearby_ids, page, per_page, period = 'all')
        popular_ids = UserItemView.popular_in_school(school_id, 50)
        favorite_ids = Favorite.joins(:item).where(items: { school_id: school_id }).group(:item_id).order(Arel.sql('COUNT(*) DESC')).limit(30).pluck(:item_id)
        purchase_ids = PurchaseHistory.joins(:item).where(items: { school_id: school_id }).group(:item_id).order(Arel.sql('COUNT(*) DESC')).limit(30).pluck(:item_id)
        
        all_popular_ids = (popular_ids + favorite_ids + purchase_ids).compact.uniq
        
        items = Item.where(id: all_popular_ids).where(deleted: false, status: 'active')
        items = apply_time_filter(items, period)
        items = items.order(created_at: :desc).page(page).per(per_page)
        
        if items.present?
          items
        elsif nearby_ids.any?
          nearby_items = Item.where(school_id: nearby_ids).where(deleted: false, status: 'active')
          nearby_items = apply_time_filter(nearby_items, period)
          nearby_items.order(created_at: :desc).page(page).per(per_page)
        else
          all_items = Item.where(deleted: false, status: 'active')
          all_items = apply_time_filter(all_items, period)
          all_items.order(created_at: :desc).page(page).per(per_page)
        end
      end
      
      def get_category_items_paginated(school_id, nearby_ids, category_ids, page, per_page)
        items = Item.where(school_id: school_id, main_category_id: category_ids)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .page(page)
                    .per(per_page)
        
        if items.present?
          items
        elsif nearby_ids.any?
          Item.where(school_id: nearby_ids, main_category_id: category_ids)
              .where(deleted: false, status: 'active')
              .order(created_at: :desc)
              .page(page)
              .per(per_page)
        else
          Item.where(main_category_id: category_ids)
              .where(deleted: false, status: 'active')
              .order(created_at: :desc)
              .page(page)
              .per(per_page)
        end
      end
      
      def get_recent_by_timeframe(school_id, nearby_ids, start_time, end_time)
        base_query = Item.where(deleted: false, status: 'active')
        items = base_query.where(school_id: school_id)
        
        if start_time.present? && end_time.present?
          items = items.where(created_at: start_time..end_time)
        elsif start_time.present?
          items = items.where('created_at > ?', start_time)
        end
        
        items = items.order(created_at: :desc)
        
        if items.exists?
          items
        elsif nearby_ids.any?
          nearby_items = base_query.where(school_id: nearby_ids)
          
          if start_time.present? && end_time.present?
            nearby_items = nearby_items.where(created_at: start_time..end_time)
          elsif start_time.present?
            nearby_items = nearby_items.where('created_at > ?', start_time)
          end
          
          nearby_items.order(created_at: :desc)
        else
          any_items = base_query
          
          if start_time.present? && end_time.present?
            any_items = any_items.where(created_at: start_time..end_time)
          elsif start_time.present?
            any_items = any_items.where('created_at > ?', start_time)
          end
          
          any_items.order(created_at: :desc)
        end
      end
      
      def render_paginated_items(items, title, page, per_page)
        render json: {
          success: true,
          title: title,
          items: format_items(items),
          pagination: {
            current_page: items.current_page,
            total_pages: items.total_pages,
            total_count: items.total_count,
            per_page: items.limit_value
          }
        }
      end
      
      def build_uniform_sections(school_id, nearby_ids, uniform_cat, gender)
        base_query = Item.where(main_category_id: uniform_cat).where(deleted: false, status: 'active')
        
        if gender.present? && gender != 'all'
          gender_id = Gender.find_by(name: gender.capitalize)&.id
          base_query = base_query.where(gender_id: gender_id) if gender_id
        end
        
        sections = [
          { title: "Summer Uniform", type: "summer", items: get_uniform_subcategory(base_query, school_id, nearby_ids, ['summer']) },
          { title: "Winter Uniform", type: "winter", items: get_uniform_subcategory(base_query, school_id, nearby_ids, ['winter']) },
          { title: "PE Kit", type: "pe_kit", items: get_uniform_subcategory(base_query, school_id, nearby_ids, ['pe', 'sport', 'gym']) },
          { title: "Accessories", type: "accessories", items: get_uniform_subcategory(base_query, school_id, nearby_ids, ['tie', 'hat', 'sock', 'belt', 'badge']) }
        ]
        
        sections.select { |s| s[:items].any? }
      end
      
      def get_uniform_subcategory(base_query, school_id, nearby_ids, keywords)
        condition = keywords.map { |k| "name ILIKE '%#{k}%' OR description ILIKE '%#{k}%'" }.join(' OR ')
        
        school_items = base_query.where(school_id: school_id).where(condition).limit(8).to_a
        
        if school_items.any?
          format_items(school_items, "At your school")
        elsif nearby_ids.any?
          nearby_items = base_query.where(school_id: nearby_ids).where(condition).limit(8).to_a
          format_items(nearby_items, "From nearby schools") if nearby_items.any?
        else
          []
        end
      end
      
      def build_sport_sections(school_id, nearby_ids, sport_cat, sport_type)
        base_query = Item.where(main_category_id: sport_cat).where(deleted: false, status: 'active')
        sports = ['rugby', 'cricket', 'hockey', 'netball', 'soccer']
        
        if sport_type.present?
          sections = [{ title: sport_type.capitalize, type: sport_type, items: get_sport_items(base_query, school_id, nearby_ids, sport_type) }]
        else
          sections = sports.map { |sport| { title: sport.capitalize, type: sport, items: get_sport_items(base_query, school_id, nearby_ids, sport) } }
        end
        
        sections.select { |s| s[:items].any? }
      end
      
      def get_sport_items(base_query, school_id, nearby_ids, sport)
        condition = "name ILIKE '%#{sport}%' OR description ILIKE '%#{sport}%'"
        
        school_items = base_query.where(school_id: school_id).where(condition).limit(8).to_a
        
        if school_items.any?
          format_items(school_items, "At your school")
        elsif nearby_ids.any?
          nearby_items = base_query.where(school_id: nearby_ids).where(condition).limit(8).to_a
          format_items(nearby_items, "From nearby schools") if nearby_items.any?
        else
          []
        end
      end     
  
      
      # ============ IMPROVED format_items METHOD ============
def format_items(items, reason = nil)
  return [] if items.blank?

  items.map do |item|
    next nil if item.nil?

    # Build clean images array
    image_urls = []

    # 1. Main cover image
    cover = item.respond_to?(:cover_photo) && item.cover_photo.present? ? item.cover_photo : 
            (item.respond_to?(:image) && item.image.present? ? item.image : nil)
    
    image_urls << cover if cover.present?

    # 2. Additional images - Handle both cases safely
    if item.respond_to?(:additional_photo) && item.additional_photo.present?
      additional = item.additional_photo

      begin
        # If it's already a string that looks like JSON array
        if additional.is_a?(String) && additional.start_with?('[')
          parsed = JSON.parse(additional)
          if parsed.is_a?(Array)
            parsed.each do |img|
              image_urls << img if img.present? && !image_urls.include?(img)
            end
          end
        # If it's already an Array (ideal case)
        elsif additional.is_a?(Array)
          additional.each do |img|
            image_urls << img if img.present? && !image_urls.include?(img)
          end
        else
          # Fallback: treat as single string
          image_urls << additional if !image_urls.include?(additional)
        end
      rescue JSON::ParserError
        # If parsing fails, treat as single image URL
        image_urls << additional if additional.present? && !image_urls.include?(additional)
      end
    end

    # Remove any duplicates and nil values
    image_urls = image_urls.compact.uniq

    # Safely extract other attributes...
    category_name = item.try(:main_category)&.try(:name)
    gender_name   = item.try(:gender)&.try(:name)
    condition_name = item.try(:item_condition)&.try(:name)
    brand_name    = item.try(:brand)&.try(:name)
    size_name     = item.try(:size)&.try(:name)
    color_name    = item.try(:color)&.try(:name)

    {
      id: item.id.to_s,
      name: item.try(:name).to_s.truncate(50),
      description: item.try(:description).to_s.truncate(80),
      price: item.try(:price).to_f,
      image: cover,
      school_id: item.try(:school_id),
      category: category_name,
      gender: gender_name,
      reason: reason,
      created_at: item.try(:created_at),
      size_name: size_name,
      color_name: color_name,
      condition_name: condition_name,
      brand_name: brand_name,
      available_quantity: item.try(:available_quantity).to_i || 0,
      images: image_urls,                    # ← This should now always be proper array of strings
      cover_photo: cover
    }
  end.compact
end




    end
  end
end