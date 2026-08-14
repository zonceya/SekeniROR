module Api
  module V1
    class RecommendationsController < ApplicationController
      include Authenticatable
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      before_action :set_user_context
      
      # ================================================================
      # HOME FEED
      # ================================================================
      
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
        
        # Cache includes user_id for personalization
        cache_key = "school:#{school_id}:user:#{@current_user&.id || 'guest'}:home"
        cached = $redis.get(cache_key)
        
        if cached
          return render json: JSON.parse(cached) 
        end
        
        # Get nearby schools once for fallbacks
        nearby_ids = find_nearby_schools(school_id)
        
        # Build home feed with unified fallback
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
        
        # Cache for 15 minutes (personalized)
        $redis.setex(cache_key, 900, feed.to_json)
        
        render json: feed
      end
      
      # ================================================================
      # 🔥 RANKED ENDPOINTS
      # ================================================================
      
      # GET /api/v1/recommendations/uniform/ranked
      def uniform_ranked
        school_id = params[:school_id] || @user_school_id
        gender = params[:gender]
        sub_category_id = params[:sub_category_id] || params[:type_id]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          category_ids: uniform_cat,
          sub_category_id: sub_category_id,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        # Apply gender filter
        if gender.present? && gender != 'all'
          gender_id = Gender.find_by(name: gender.capitalize)&.id
          tagged_items = tagged_items.select { |item| item.gender_id == gender_id } if gender_id
        end
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        render json: {
          success: true,
          school_id: school_id,
          gender: gender || 'all',
          total_count: total_count,
          items: format_items_with_relevance(paginated_items),
          pagination: {
            current_page: page.to_i,
            per_page: per_page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil
          }
        }
      end
      
      # GET /api/v1/recommendations/sport/ranked
      def sport_ranked
        school_id = params[:school_id] || @user_school_id
        sport_type = params[:sport_type]
        sub_category_id = params[:sub_category_id] || params[:type_id]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          category_ids: sport_cat,
          sub_category_id: sub_category_id,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        # Apply sport type filter
        if sport_type.present?
          sub = SubCategory.find_by(name: sport_type.capitalize, main_category_id: sport_cat)
          tagged_items = tagged_items.select { |item| item.sub_category_id == sub.id } if sub
        end
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        render json: {
          success: true,
          school_id: school_id,
          total_count: total_count,
          items: format_items_with_relevance(paginated_items),
          pagination: {
            current_page: page.to_i,
            per_page: per_page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil
          }
        }
      end
      
      # GET /api/v1/recommendations/recent/ranked
      def recent_ranked
        school_id = params[:school_id] || @user_school_id
        period = params[:period]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          period: period,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        title = case period
        when 'today' then "Added Today"
        when 'yesterday' then "Added Yesterday"
        when 'week' then "Added This Week"
        else "Recently Added"
        end
        
        render json: {
          success: true,
          school_id: school_id,
          title: title,
          total_count: total_count,
          items: format_items_with_relevance(paginated_items),
          pagination: {
            current_page: page.to_i,
            per_page: per_page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil
          }
        }
      end
      
      # GET /api/v1/recommendations/search/ranked
      def search_ranked
        query = params[:query]
        school_id = params[:school_id] || @user_school_id
        category_id = params[:category_id]
        sub_category_id = params[:sub_category_id]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "Search query required" }, status: :bad_request if query.blank?
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Search ALL items globally
        items = Item
          .where(deleted: false, status: 'active')
          .where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
          .where(is_system: false) # Exclude system items from search
        
        items = items.where(main_category_id: category_id) if category_id.present?
        items = items.where(sub_category_id: sub_category_id) if sub_category_id.present?
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        items = with_all_associations(items)
        
        # Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # If no results, include system items
        if tagged_items.empty?
          system_items = get_system_items(category_id ? [category_id] : nil, sub_category_id, per_page.to_i * 2)
          tagged_items = tag_and_rank_items(system_items, school_id, nearby_ids)
        end
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        render json: {
          success: true,
          query: query,
          school_id: school_id,
          total_count: total_count,
          items: format_items_with_relevance(paginated_items),
          pagination: {
            current_page: page.to_i,
            per_page: per_page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil
          }
        }
      end
      
      # GET /api/v1/recommendations/recommended/ranked
      def recommended_ranked
        school_id = params[:school_id] || @user_school_id
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        period = params[:period] || 'all'
        category_id = params[:category_id]
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          category_ids: category_id,
          period: period,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        render json: {
          success: true,
          school_id: school_id,
          total_count: total_count,
          items: format_items_with_relevance(paginated_items),
          pagination: {
            current_page: page.to_i,
            per_page: per_page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil
          }
        }
      end
      
      # GET /api/v1/recommendations/trending/ranked
      def trending_ranked
        school_id = params[:school_id] || @user_school_id
        period = params[:period] || 'today'
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Try Redis trending first (permanent, never expires)
        redis_key = "school:#{school_id}:trending:#{period}"
        trending_ids = $redis.zrevrange(redis_key, 0, 99)
        
        if trending_ids.any?
          items = with_all_associations(Item)
                  .where(id: trending_ids)
                  .where(deleted: false, status: 'active', is_system: false)
          
          items = items.where('price >= ?', min_price) if min_price.present?
          items = items.where('price <= ?', max_price) if max_price.present?
          items = items.to_a
          
          if items.any?
            tagged_items = tag_and_rank_items(items, school_id, nearby_ids)
            total_count = tagged_items.size
            paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
            
            return render json: {
              success: true,
              school_id: school_id,
              period: period,
              total_count: total_count,
              items: format_items_with_relevance(paginated_items),
              pagination: {
                current_page: page.to_i,
                per_page: per_page.to_i,
                total_pages: (total_count.to_f / per_page.to_i).ceil
              }
            }
          end
        end
        
        # Fallback to unified method (will include system items if needed)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          period: period,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        render json: {
          success: true,
          school_id: school_id,
          period: period,
          total_count: total_count,
          items: format_items_with_relevance(paginated_items),
          pagination: {
            current_page: page.to_i,
            per_page: per_page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil
          }
        }
      end
      
      # GET /api/v1/recommendations/essentials/ranked
      def essentials_ranked
        school_id = params[:school_id] || @user_school_id
        category = params[:category]&.downcase
        sub_category_id = params[:sub_category_id] || params[:type_id]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].to_f if params[:min_price].present?
        max_price = params[:max_price].to_f if params[:max_price].present?
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        category_map = {
          'uniforms' => MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id),
          'sports' => MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id),
          'accessories' => MainCategory.where(name: ['Accessories']).pluck(:id),
          'stationery' => MainCategory.where(name: ['Stationery']).pluck(:id)
        }
        
        if category.present? && category_map[category].present?
          tagged_items = get_items_with_fallback(
            school_id: school_id,
            nearby_ids: nearby_ids,
            limit: per_page.to_i * 2,
            category_ids: category_map[category],
            sub_category_id: sub_category_id,
            min_price: min_price,
            max_price: max_price,
            excluded_ids: get_excluded_ids
          )
          
          total_count = tagged_items.size
          paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
          
          return render json: {
            success: true,
            school_id: school_id,
            category: category,
            total_count: total_count,
            items: format_items_with_relevance(paginated_items),
            pagination: {
              current_page: page.to_i,
              per_page: per_page.to_i,
              total_pages: (total_count.to_f / per_page.to_i).ceil
            }
          }
        end
        
        # Return all essentials categories
        all_items = []
        category_map.each do |cat_name, cat_ids|
          tagged_items = get_items_with_fallback(
            school_id: school_id,
            nearby_ids: nearby_ids,
            limit: 6,
            category_ids: cat_ids,
            min_price: min_price,
            max_price: max_price,
            excluded_ids: get_excluded_ids
          )
          
          all_items << {
            title: cat_name.capitalize,
            category: cat_name,
            items: format_items_with_relevance(tagged_items.first(6))
          }
        end
        
        render json: {
          success: true,
          school_id: school_id,
          sections: all_items
        }
      end
      
      # ================================================================
      # LEGACY ENDPOINTS (Backward Compatibility)
      # ================================================================
      
      # GET /api/v1/recommendations/recommended/all
      def recommended_all
        school_id = params[:school_id] || @user_school_id
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        period = params[:period] || 'all'
        exclude_item_id = params[:exclude_item_id]
        category_id = params[:category_id]
        
        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          category_ids: category_id,
          period: period,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        # Paginate
        total_count = tagged_items.size
        paginated_items = tagged_items[(page.to_i - 1) * per_page.to_i, per_page.to_i] || []
        
        title = category_id.present? ? "#{MainCategory.find_by(id: category_id)&.name || 'Items'}" : "Recommended for you"
        
        render json: {
          success: true,
          title: title,
          items: format_items(paginated_items),
          pagination: {
            current_page: page.to_i,
            total_pages: (total_count.to_f / per_page.to_i).ceil,
            total_count: total_count,
            per_page: per_page.to_i
          }
        }
      end
      
      # GET /api/v1/recommendations/essentials/all
      def essentials_all
        school_id = params[:school_id] || @user_school_id
        category = params[:category]&.downcase
        sub_category_id = params[:sub_category_id] || params[:type_id]
        page = params[:page] || 1
        per_page = params[:per_page] || 30

        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil

        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id

        nearby_ids = find_nearby_schools(school_id)

        # If sub_category_id is provided
        if sub_category_id.present?
          tagged_items = get_items_with_fallback(
            school_id: school_id,
            nearby_ids: nearby_ids,
            limit: per_page.to_i * 2,
            sub_category_id: sub_category_id,
            min_price: min_price,
            max_price: max_price,
            excluded_ids: get_excluded_ids
          )
          
          sub = SubCategory.find_by(id: sub_category_id)
          sub_name = sub&.name || "Items"
          
          return render_paginated_items(tagged_items, "#{sub_name} Essentials", page, per_page)
        end

        # If category is provided
        category_map = {
          'uniforms' => MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id),
          'sports' => MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id),
          'accessories' => MainCategory.where(name: ['Accessories']).pluck(:id),
          'stationery' => MainCategory.where(name: ['Stationery']).pluck(:id)
        }

        if category.present? && category_map[category].present?
          tagged_items = get_items_with_fallback(
            school_id: school_id,
            nearby_ids: nearby_ids,
            limit: per_page.to_i * 2,
            category_ids: category_map[category],
            min_price: min_price,
            max_price: max_price,
            excluded_ids: get_excluded_ids
          )
          
          return render_paginated_items(tagged_items, "#{category.capitalize} Essentials", page, per_page)
        end

        # Return all categories
        all_items = []
        category_map.each do |cat_name, cat_ids|
          tagged_items = get_items_with_fallback(
            school_id: school_id,
            nearby_ids: nearby_ids,
            limit: 6,
            category_ids: cat_ids,
            min_price: min_price,
            max_price: max_price,
            excluded_ids: get_excluded_ids
          )
          
          all_items << {
            title: "#{cat_name.capitalize} Essentials",
            category: cat_name,
            items: format_items(tagged_items.first(6))
          }
        end

        render json: {
          success: true,
          school_id: school_id,
          sections: all_items
        }
      end
      
      # GET /api/v1/recommendations/trending/all
      def trending_all
        school_id = params[:school_id] || @user_school_id
        period = params[:period] || 'today'
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          period: period,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        render_paginated_items(tagged_items, "Trending #{period}", page, per_page)
      end
      
      # GET /api/v1/recommendations/recent/all
      def recent_all
        school_id = params[:school_id] || @user_school_id
        period = params[:period]
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        # Use unified fallback
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          period: period,
          min_price: min_price,
          max_price: max_price,
          excluded_ids: get_excluded_ids
        )
        
        title = case period
        when 'today' then "Added Today"
        when 'yesterday' then "Added Yesterday"
        when 'week' then "Added This Week"
        else "Recently Added"
        end
        
        render_paginated_items(tagged_items, title, page, per_page)
      end
      
      # GET /api/v1/recommendations/uniform (legacy)
      def uniform
        school_id = params[:school_id] || @user_school_id
        gender = params[:gender]
        sub_category_id = params[:sub_category_id] || params[:type_id]
        
        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
        nearby_ids = find_nearby_schools(school_id)
        
        sections = build_uniform_sections_universal(school_id, nearby_ids, uniform_cat, gender, sub_category_id, min_price, max_price)
        
        render json: {
          success: true,
          school_id: school_id,
          gender: gender || 'all',
          sections: sections
        }
      end
      
      # GET /api/v1/recommendations/sport (legacy)
      def sport
        school_id = params[:school_id] || @user_school_id
        sport_type = params[:sport_type]
        sub_category_id = params[:sub_category_id] || params[:type_id]
        
        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        nearby_ids = find_nearby_schools(school_id)
        
        sections = build_sport_sections_universal(school_id, nearby_ids, sport_cat, sport_type, sub_category_id, min_price, max_price)
        
        render json: {
          success: true,
          school_id: school_id,
          sections: sections
        }
      end
      
      # GET /api/v1/recommendations/recent (legacy)
      def recent
        school_id = params[:school_id] || @user_school_id
        period = params[:period]
        
        min_price = params[:min_price].present? ? params[:min_price].to_f : nil
        max_price = params[:max_price].present? ? params[:max_price].to_f : nil
        
        return render json: { success: false, error: "School ID required" }, status: :bad_request unless school_id
        
        nearby_ids = find_nearby_schools(school_id)
        
        if period.present?
          tagged_items = get_items_with_fallback(
            school_id: school_id,
            nearby_ids: nearby_ids,
            limit: 10,
            period: period,
            min_price: min_price,
            max_price: max_price,
            excluded_ids: get_excluded_ids
          )
          
          render json: {
            success: true,
            school_id: school_id,
            title: period_title(period),
            period: period,
            items: format_items(tagged_items)
          }
        else
          sections = []
          ['today', 'yesterday', 'week'].each do |p|
            tagged_items = get_items_with_fallback(
              school_id: school_id,
              nearby_ids: nearby_ids,
              limit: 10,
              period: p,
              min_price: min_price,
              max_price: max_price,
              excluded_ids: get_excluded_ids
            )
            
            sections << {
              title: period_title(p),
              period: p,
              items: format_items(tagged_items)
            }
          end
          
          render json: {
            success: true,
            school_id: school_id,
            sections: sections
          }
        end
      end
      
      # ================================================================
      # TRACKING ENDPOINTS
      # ================================================================
      
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
            # Increment trending counts (permanent, never expire)
            $redis.zincrby("school:#{school_id}:trending:today", 1, item_id)
            $redis.zincrby("school:#{school_id}:trending:week", 1, item_id)
            $redis.zincrby("school:#{school_id}:trending:month", 1, item_id)
            $redis.zincrby("school:#{school_id}:trending:total", 1, item_id)
            
            # Clear user's cache
            if @current_user && school_id
              $redis.del("school:#{school_id}:user:#{@current_user.id}:home")
              $redis.del("school:#{school_id}:user:#{@current_user.id}:recommended")
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
      
      # ================================================================
      # PRIVATE HELPERS
      # ================================================================
      
      private
      
      # ================================================================
      # 🔥 UNIFIED FALLBACK HELPER
      # ================================================================
      
def get_items_with_fallback(options = {})
  school_id      = options[:school_id]
  nearby_ids     = options[:nearby_ids] || []
  limit          = options[:limit] || 12
  category_ids   = options[:category_ids]
  sub_category_id = options[:sub_category_id]
  period         = options[:period]
  min_price      = options[:min_price]
  max_price      = options[:max_price]
  excluded_ids   = options[:excluded_ids] || []

  items = []
  collected_ids = []

  # -------------------------------------------------
  # Step 1: Real items from the selected school
  # -------------------------------------------------
  school_real = get_items_by_location(school_id, category_ids, sub_category_id, period, min_price, max_price, excluded_ids)
  school_real = with_all_associations(school_real)
  items += school_real.to_a
  collected_ids += items.map(&:id)

  # -------------------------------------------------
  # Step 2: System items that BELONG to the selected school  ← NEW
  # -------------------------------------------------
  if items.size < limit
    school_system = Item.where(
      school_id: school_id,
      is_system: true,
      deleted: false,
      status: 'active'
    )
    school_system = school_system.where(main_category_id: category_ids) if category_ids.present?
    school_system = school_system.where(sub_category_id: sub_category_id) if sub_category_id.present?
    school_system = school_system.where('price >= ?', min_price) if min_price.present?
    school_system = school_system.where('price <= ?', max_price) if max_price.present?
    school_system = school_system.where.not(id: excluded_ids + collected_ids) if (excluded_ids + collected_ids).any?
    school_system = apply_time_filter(school_system, period) if period.present?
    school_system = with_all_associations(school_system)
    
    items += school_system.limit(limit - items.size).to_a
    collected_ids = items.map(&:id)
  end

  needed = limit - items.size
  return tag_and_rank_items(items, school_id, nearby_ids) if needed <= 0

  # -------------------------------------------------
  # Step 3: Nearby schools (real items only)
  # -------------------------------------------------
  if nearby_ids.any? && needed > 0
    nearby = get_items_by_location(nearby_ids, category_ids, sub_category_id, period, min_price, max_price, excluded_ids + collected_ids)
    nearby = with_all_associations(nearby)
    items += nearby.limit(needed).to_a
    collected_ids = items.map(&:id)
    needed = limit - items.size
  end

  # -------------------------------------------------
  # Step 4: Same province
  # -------------------------------------------------
  if needed > 0
    school = School.find_by(id: school_id)
    if school&.province_id
      province = get_items_by_province(school.province_id, category_ids, sub_category_id, period, min_price, max_price, excluded_ids + collected_ids)
      province = with_all_associations(province)
      items += province.limit(needed).to_a
      collected_ids = items.map(&:id)
      needed = limit - items.size
    end
  end

  # -------------------------------------------------
  # Step 5: Global real items
  # -------------------------------------------------
  if needed > 0
    global = get_items_global(category_ids, sub_category_id, period, min_price, max_price, excluded_ids + collected_ids)
    global = with_all_associations(global)
    items += global.limit(needed).to_a
    collected_ids = items.map(&:id)
    needed = limit - items.size
  end

  # -------------------------------------------------
  # Step 6: Remaining system items from anywhere (true last resort)
  # -------------------------------------------------
  if needed > 0
    system_items = get_system_items(category_ids, sub_category_id, needed)
    # Avoid duplicates
    system_items = system_items.reject { |i| collected_ids.include?(i.id) }
    items += system_items.first(needed)
  end

  tag_and_rank_items(items, school_id, nearby_ids)
end
      
      def get_items_by_location(school_ids, category_ids, sub_category_id, period, min_price, max_price, excluded_ids)
        scope = Item.where(deleted: false, status: 'active', is_system: false)
        scope = scope.where(school_id: school_ids) if school_ids.present?
        scope = scope.where(main_category_id: category_ids) if category_ids.present?
        scope = scope.where(sub_category_id: sub_category_id) if sub_category_id.present?
        scope = scope.where('price >= ?', min_price) if min_price.present?
        scope = scope.where('price <= ?', max_price) if max_price.present?
        scope = scope.where.not(id: excluded_ids) if excluded_ids.any?
        scope = apply_time_filter(scope, period) if period.present?  
        scope
      end
      
      def get_items_by_province(province_id, category_ids, sub_category_id, period, min_price, max_price, excluded_ids)
        school_ids = School.where(province_id: province_id, is_system: false).pluck(:id)
        get_items_by_location(school_ids, category_ids, sub_category_id, period, min_price, max_price, excluded_ids)
      end
      
      def get_items_global(category_ids, sub_category_id, period, min_price, max_price, excluded_ids)
        get_items_by_location(nil, category_ids, sub_category_id, period, min_price, max_price, excluded_ids)
      end
      
      def get_system_items(category_ids, sub_category_id, limit)
        scope = Item.where(is_system: true, deleted: false, status: 'active')
        scope = scope.where(main_category_id: category_ids) if category_ids.present?
        scope = scope.where(sub_category_id: sub_category_id) if sub_category_id.present?
        scope = scope.order(display_order: :asc, view_count: :desc)
        scope = with_all_associations(scope)
        scope.limit(limit).to_a
      end
      
      def get_excluded_ids
        return [] unless @current_user
        
        viewed_ids = UserItemView.where(user_id: @current_user.id).recent.pluck(:item_id)
        favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
        purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
        
        (viewed_ids + favorited_ids + purchased_ids).uniq.first(50)
      end
      
      # ================================================================
      # 🔧 RANKING HELPER METHODS
      # ================================================================
      
     def tag_and_rank_items(items, school_id, nearby_ids)
  return [] if items.blank?

  nearby_ids = nearby_ids.map(&:to_i) if nearby_ids.present?
  school_id  = school_id.to_i

  tagged = items.map do |item|
    relevance = if item.school_id == school_id
                  'school_match'
                elsif nearby_ids.present? && nearby_ids.include?(item.school_id)
                  'nearby_match'
                elsif item.is_system
                  'system'
                else
                  'other'
                end

    item.define_singleton_method(:relevance) { relevance }
    item
  end

  # Correct order: school first → nearby → system → other
  # Newest first within each group
  tagged.sort_by do |item|
    case item.relevance
    when 'school_match' then [0, -item.created_at.to_i]
    when 'nearby_match' then [1, -item.created_at.to_i]
    when 'system'       then [2, item.display_order || 0]
    else                     [3, -item.created_at.to_i]
    end
  end
  # NO .reverse
end
      
      def format_items_with_relevance(items)
        return [] if items.blank?
        
        items.map do |item|
          primary_variant = item.item_variants.find(&:is_active?)
          actual_price = primary_variant&.price&.to_f || item.price.to_f
          
          {
            id: item.id,
            name: item.name,
            price: actual_price,
            description: item.description,
            main_category: item.main_category&.name,
            main_category_id: item.main_category_id,
            sub_category: item.sub_category&.name,
            sub_category_id: item.sub_category_id,
            gender: item.gender&.name,
            gender_id: item.gender_id,
            condition: item.item_condition&.name,
            brand: item.brand&.name,
            school_name: item.school&.name,
            school_id: item.school_id,
            relevance: item.relevance,
            is_system: item.is_system,
            images: item.all_image_urls,  # REMOVED DUPLICATE
            cover_photo: item.cover_photo,
            created_at: item.created_at.iso8601,
            view_count: item.view_count || 0
          }
        end
      end
      
      def format_items(items, reason = nil)
        return [] if items.blank?

        items.map do |item|
          primary_variant = item.item_variants.find(&:is_active?)
          actual_price = primary_variant&.price&.to_f || item.price.to_f
          qty = item.quantity.to_i
          reserved = item.try(:reserved).to_i

          {
            id: item.id.to_s,
            name: item.name.to_s.truncate(50),
            description: item.description.to_s.truncate(80),
            price: actual_price,
            quantity: qty,
            reserved: reserved,
            available_quantity: [qty - reserved, 0].max,
            status: item.status,
            is_sold: sold?(item),
            view_count: item.view_count || 0,
            image: item.cover_photo,
            school_id: item.school_id,
            school: item.school&.name,
            school_name: item.school&.name,
            category: item.main_category&.name,
            main_category_id: item.main_category_id,
            sub_category_id: item.sub_category_id,
            gender: item.gender&.name,
            gender_id: item.gender_id,
            reason: reason,
            is_system: item.is_system,
            images: item.all_image_urls,
            cover_photo: item.cover_photo,
            created_at: item.created_at
          }
        end.compact
      end
      
      def sold?(item)
        status = item.status
        qty = item.quantity.to_i

        case status
        when String then status.downcase == 'sold' || qty <= 0
        when Integer then status == 2 || qty <= 0
        else qty <= 0
        end
      end
      
      # ================================================================
      # EXISTING HELPERS
      # ================================================================
      
      def with_all_associations(scope)
        scope.includes(:main_category, :sub_category, :gender, :item_condition, :brand, :school, :item_variants)
      end
      
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
                        .where(is_system: false)
                        .limit(10)
                        .pluck(:id)
          return nearby if nearby.any?
        end
        
        if school.province_id
          nearby = School.where(province_id: school.province_id)
                        .where.not(id: school_id)
                        .where(is_system: false)
                        .limit(10)
                        .pluck(:id)
          return nearby if nearby.any?
        end
        
        School.where(is_system: false).where.not(id: school_id).limit(10).pluck(:id)
      end
      
      def apply_time_filter(scope, period)
        case period
        when 'today'
          scope.where('items.created_at >= ?', Time.current.beginning_of_day)
        when 'yesterday'
          scope.where(items: { created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day })
        when 'week'
          scope.where('items.created_at >= ?', 7.days.ago)
        when 'month'
          scope.where('items.created_at >= ?', 30.days.ago)
        else
          scope
        end
      end
      
      def recommended_items_with_fallback(school_id, nearby_ids)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: 12,
          excluded_ids: get_excluded_ids
        )
        
        format_items(tagged_items, "Recommended for you")
      end
      
      def school_essentials_with_fallback(school_id, nearby_ids)
        uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
        sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
        accessory_cat = MainCategory.where(name: ['Accessories']).pluck(:id)
        stationery_cat = MainCategory.where(name: ['Stationery']).pluck(:id)
        
        {
          uniforms: get_category_items_with_fallback(school_id, nearby_ids, uniform_cat, "Uniforms", 6),
          sports: get_category_items_with_fallback(school_id, nearby_ids, sport_cat, "Sports Gear", 6),
          accessories: get_category_items_with_fallback(school_id, nearby_ids, accessory_cat, "Accessories", 6),
          stationery: get_category_items_with_fallback(school_id, nearby_ids, stationery_cat, "Stationery", 6)
        }
      end
      
      def get_category_items_with_fallback(school_id, nearby_ids, category_ids, category_name, limit = 6)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: limit,
          category_ids: category_ids,
          excluded_ids: get_excluded_ids
        )
        
        format_items(tagged_items, category_name)
      end
      
      def trending_items_with_fallback(school_id, nearby_ids)
        # Try Redis trending first (permanent)
        trending_ids = $redis.zrevrange("school:#{school_id}:trending:today", 0, 14)
        
        if trending_ids.any?
          items = with_all_associations(Item)
                  .where(id: trending_ids)
                  .where(deleted: false, status: 'active', is_system: false)
                  .to_a
          
          if items.any?
            tagged_items = tag_and_rank_items(items, school_id, nearby_ids)
            return format_items(tagged_items, "Trending today at your school")
          end
        end
        
        # Fallback to unified method
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: 12,
          excluded_ids: get_excluded_ids
        )
        
        format_items(tagged_items, "Trending")
      end
      
      def recent_items_with_fallback(school_id, nearby_ids)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: 10,
          excluded_ids: get_excluded_ids
        )
        
        format_items(tagged_items, "Recently Added")
      end
      
      def render_paginated_items(items, title, page, per_page)
        # Handle case where items is an array
        if items.is_a?(Array)
          total_count = items.size
          total_pages = (total_count.to_f / per_page.to_i).ceil
          current_page = page.to_i
          
          return render json: {
            success: true,
            title: title,
            items: format_items(items),
            pagination: {
              current_page: current_page,
              total_pages: total_pages,
              total_count: total_count,
              per_page: per_page.to_i
            }
          }
        end
        
        # Normal paginated collection
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
      
      def period_title(period)
        case period
        when 'today' then "Added Today"
        when 'yesterday' then "Added Yesterday"
        when 'week' then "Added This Week"
        else "Recent Items"
        end
      end
      
      # ================================================================
      # UNIVERSAL BUILD METHODS
      # ================================================================
      
      def build_uniform_sections_universal(school_id, nearby_ids, uniform_cat, gender, sub_category_id, min_price = nil, max_price = nil)
        if sub_category_id.present?
          sub = SubCategory.find_by(id: sub_category_id, main_category_id: uniform_cat, is_active: true)
          if sub
            tagged_items = get_items_with_fallback(
              school_id: school_id,
              nearby_ids: nearby_ids,
              limit: 8,
              category_ids: uniform_cat,
              sub_category_id: sub.id,
              min_price: min_price,
              max_price: max_price,
              excluded_ids: get_excluded_ids
            )
            
            return [{
              title: sub.name,
              type: "uniform_sub_category",
              sub_category_id: sub.id,
              items: format_items(tagged_items)
            }].select { |s| s[:items].any? }
          else
            return []
          end
        end

        SubCategory
          .where(main_category_id: uniform_cat, is_active: true)
          .order(:display_order)
          .map do |sub|
            tagged_items = get_items_with_fallback(
              school_id: school_id,
              nearby_ids: nearby_ids,
              limit: 8,
              category_ids: uniform_cat,
              sub_category_id: sub.id,
              min_price: min_price,
              max_price: max_price,
              excluded_ids: get_excluded_ids
            )
            
            {
              title: sub.name,
              type: "uniform_sub_category",
              sub_category_id: sub.id,
              items: format_items(tagged_items)
            }
          end
          .select { |s| s[:items].any? }
      end
      
      def build_sport_sections_universal(school_id, nearby_ids, sport_cat, sport_type, sub_category_id, min_price = nil, max_price = nil)
        if sub_category_id.present?
          sub = SubCategory.find_by(id: sub_category_id, main_category_id: sport_cat, is_active: true)
          if sub
            tagged_items = get_items_with_fallback(
              school_id: school_id,
              nearby_ids: nearby_ids,
              limit: 8,
              category_ids: sport_cat,
              sub_category_id: sub.id,
              min_price: min_price,
              max_price: max_price,
              excluded_ids: get_excluded_ids
            )
            
            return [{
              title: sub.name,
              type: "sport_sub_category",
              sub_category_id: sub.id,
              items: format_items(tagged_items)
            }].select { |s| s[:items].any? }
          else
            return []
          end
        end
        
        if sport_type.present?
          sub = SubCategory.find_by(name: sport_type.capitalize, main_category_id: sport_cat, is_active: true)
          if sub
            tagged_items = get_items_with_fallback(
              school_id: school_id,
              nearby_ids: nearby_ids,
              limit: 8,
              category_ids: sport_cat,
              sub_category_id: sub.id,
              min_price: min_price,
              max_price: max_price,
              excluded_ids: get_excluded_ids
            )
            
            return [{
              title: sub.name,
              type: "sport_sub_category",
              sub_category_id: sub.id,
              items: format_items(tagged_items)
            }].select { |s| s[:items].any? }
          else
            return []
          end
        end

        SubCategory
          .where(main_category_id: sport_cat, is_active: true)
          .order(:display_order)
          .map do |sub|
            tagged_items = get_items_with_fallback(
              school_id: school_id,
              nearby_ids: nearby_ids,
              limit: 8,
              category_ids: sport_cat,
              sub_category_id: sub.id,
              min_price: min_price,
              max_price: max_price,
              excluded_ids: get_excluded_ids
            )
            
            {
              title: sub.name,
              type: "sport_sub_category",
              sub_category_id: sub.id,
              items: format_items(tagged_items)
            }
          end
          .select { |s| s[:items].any? }
      end
      
      # ================================================================
      # LEGACY METHODS
      # ================================================================
      
      def get_items_by_subcategory_universal(school_id, nearby_ids, sub_category_id, page = 1, per_page = 8)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          sub_category_id: sub_category_id,
          excluded_ids: get_excluded_ids
        )
        
        # Wrap for pagination compatibility
        def tagged_items.current_page; 1; end
        def tagged_items.total_pages; 1; end
        def tagged_items.total_count; size; end
        def tagged_items.limit_value; size; end
        
        tagged_items
      end
      
      def get_category_items_paginated(school_id, nearby_ids, category_ids, page, per_page)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          category_ids: category_ids,
          excluded_ids: get_excluded_ids
        )
        
        # Wrap for pagination compatibility
        def tagged_items.current_page; page.to_i; end
        def tagged_items.total_pages; (size.to_f / per_page.to_i).ceil; end
        def tagged_items.total_count; size; end
        def tagged_items.limit_value; per_page.to_i; end
        
        tagged_items
      end
      
      def get_recent_by_timeframe(school_id, nearby_ids, start_time, end_time)
        period = if start_time.present? && end_time.present?
          'yesterday'
        elsif start_time.present?
          if start_time == Time.now.beginning_of_day
            'today'
          elsif start_time == 7.days.ago
            'week'
          else
            nil
          end
        end
        
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: 20,
          period: period,
          excluded_ids: get_excluded_ids
        )
        
        # Wrap for pagination compatibility
        def tagged_items.current_page; 1; end
        def tagged_items.total_pages; 1; end
        def tagged_items.total_count; size; end
        def tagged_items.limit_value; size; end
        
        tagged_items
      end
      
      def popular_items_paginated(school_id, nearby_ids, page, per_page, period = 'all')
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: per_page.to_i * 2,
          period: period,
          excluded_ids: get_excluded_ids
        )
        
        # Wrap for pagination compatibility
        def tagged_items.current_page; page.to_i; end
        def tagged_items.total_pages; (size.to_f / per_page.to_i).ceil; end
        def tagged_items.total_count; size; end
        def tagged_items.limit_value; per_page.to_i; end
        
        tagged_items
      end
      
      def apply_price_filter(items, min_price, max_price)
        return items if min_price.nil? && max_price.nil?
        
        if items.respond_to?(:where)
          items = items.where('price >= ?', min_price) if min_price.present?
          items = items.where('price <= ?', max_price) if max_price.present?
          items
        else
          # Handle array case
          filtered = items
          filtered = filtered.select { |i| i.price >= min_price } if min_price.present?
          filtered = filtered.select { |i| i.price <= max_price } if max_price.present?
          filtered
        end
      end
      
      def get_recent_items_by_period(school_id, nearby_ids, period)
        tagged_items = get_items_with_fallback(
          school_id: school_id,
          nearby_ids: nearby_ids,
          limit: 10,
          period: period,
          excluded_ids: get_excluded_ids
        )
        
        format_items(tagged_items, period_title(period))
      end
    end
  end
end