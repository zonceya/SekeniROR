# app/controllers/api/v1/recommendations_controller.rb
module Api
  module V1
    class RecommendationsController < ApplicationController
      include Authenticatable
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      before_action :set_user_context
      
      # ================================================================
      # HOME FEED (KEEP EXISTING)
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
      
      # ================================================================
      # 🔥 NEW RANKED ENDPOINTS (USE THESE!)
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
        
        # STEP 1: Get ALL uniform items globally
        items = Item
          .where(main_category_id: uniform_cat)
          .where(deleted: false, status: 'active')
        
        # Apply filters
        items = items.where(sub_category_id: sub_category_id) if sub_category_id.present?
        if gender.present? && gender != 'all'
          gender_id = Gender.find_by(name: gender.capitalize)&.id
          items = items.where(gender_id: gender_id) if gender_id
        end
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        
        items = with_all_associations(items)
        
        # STEP 2: Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # STEP 3: Paginate
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
        
        # STEP 1: Get ALL sport items globally
        items = Item
          .where(main_category_id: sport_cat)
          .where(deleted: false, status: 'active')
        
        # Apply filters
        items = items.where(sub_category_id: sub_category_id) if sub_category_id.present?
        if sport_type.present?
          sub = SubCategory.find_by(name: sport_type.capitalize, main_category_id: sport_cat)
          items = items.where(sub_category_id: sub.id) if sub
        end
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        
        items = with_all_associations(items)
        
        # STEP 2: Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # STEP 3: Paginate
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
        
        # STEP 1: Get ALL recent items globally
        items = Item.where(deleted: false, status: 'active')
        
        case period
        when 'today'
          items = items.where('created_at >= ?', Time.now.beginning_of_day)
        when 'yesterday'
          items = items.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day)
        when 'week'
          items = items.where('created_at >= ?', 7.days.ago)
        end
        
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        items = with_all_associations(items)
        
        # STEP 2: Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # STEP 3: Paginate
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
        
        # STEP 1: Search ALL items globally
        items = Item
          .where(deleted: false, status: 'active')
          .where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
        
        items = items.where(main_category_id: category_id) if category_id.present?
        items = items.where(sub_category_id: sub_category_id) if sub_category_id.present?
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        items = with_all_associations(items)
        
        # STEP 2: Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # STEP 3: Paginate
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
        
        # STEP 1: Get ALL items globally
        items = Item.where(deleted: false, status: 'active')
        items = items.where(main_category_id: category_id) if category_id.present?
        items = apply_time_filter(items, period)
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        
        # Exclude user's viewed/favorited/purchased
        if @current_user
          viewed_ids = UserItemView.where(user_id: @current_user.id).recent.pluck(:item_id)
          favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
          purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
          excluded_ids = (viewed_ids + favorited_ids + purchased_ids).uniq.first(50)
          items = items.where.not(id: excluded_ids) if excluded_ids.any?
        end
        
        items = with_all_associations(items)
        
        # STEP 2: Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # STEP 3: Paginate
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
        
        # STEP 1: Get trending IDs from Redis
        redis_key = "school:#{school_id}:trending:#{period}"
        trending_ids = $redis.zrevrange(redis_key, 0, 99)
        
        if trending_ids.blank?
          case period
          when 'today' then days = 1
          when 'week' then days = 7
          when 'month' then days = 30
          else days = 1
          end
          trending_ids = UserItemView.popular_in_school(school_id, 50, days)
        end
        
        # STEP 2: Get ALL trending items globally
        items = Item
          .where(id: trending_ids)
          .where(deleted: false, status: 'active')
        
        items = items.where('price >= ?', min_price) if min_price.present?
        items = items.where('price <= ?', max_price) if max_price.present?
        items = with_all_associations(items)
        
        # STEP 3: Tag and rank
        tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
        
        # STEP 4: Paginate
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
          items = Item
            .where(main_category_id: category_map[category])
            .where(deleted: false, status: 'active')
          
          items = items.where(sub_category_id: sub_category_id) if sub_category_id.present?
          items = items.where('price >= ?', min_price) if min_price.present?
          items = items.where('price <= ?', max_price) if max_price.present?
          items = with_all_associations(items)
          
          tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
          
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
          items = Item
            .where(main_category_id: cat_ids)
            .where(deleted: false, status: 'active')
          
          items = items.where('price >= ?', min_price) if min_price.present?
          items = items.where('price <= ?', max_price) if max_price.present?
          items = with_all_associations(items)
          
          tagged_items = tag_and_rank_items(items.to_a, school_id, nearby_ids)
          
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
      # LEGACY ENDPOINTS (KEEP FOR BACKWARD COMPATIBILITY)
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
        
        # If category_id is provided, check if the user's school has items in that category
        if category_id.present? && @current_user
          # Get user's viewed/favorited/purchased IDs for exclusion
          viewed_ids = UserItemView.where(user_id: @current_user.id).recent.pluck(:item_id)
          favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
          purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
          excluded_ids = (viewed_ids + favorited_ids + purchased_ids).uniq.first(50)
          
          # First try user's school with the specific category
          items = with_all_associations(Item)
                  .where(school_id: school_id)
                  .where(main_category_id: category_id)
                  .where(deleted: false, status: 'active')
                  .where.not(id: excluded_ids)
          items = items.where.not(id: exclude_item_id) if exclude_item_id.present?
          items = apply_time_filter(items, period)
          items = apply_price_filter(items, min_price, max_price)
          items = items.order(created_at: :desc).page(page).per(per_page)
          
          if items.present?
            category_name = MainCategory.find_by(id: category_id)&.name || "Items"
            return render_paginated_items(items, "#{category_name} at your school", page, per_page)
          end
          
          # If no items in user's school for this category, try nearby schools
          if nearby_ids.any?
            items = with_all_associations(Item)
                    .where(school_id: nearby_ids)
                    .where(main_category_id: category_id)
                    .where(deleted: false, status: 'active')
                    .where.not(id: excluded_ids)
            items = items.where.not(id: exclude_item_id) if exclude_item_id.present?
            items = apply_time_filter(items, period)
            items = apply_price_filter(items, min_price, max_price)
            items = items.order(created_at: :desc).page(page).per(per_page)
            
            if items.present?
              category_name = MainCategory.find_by(id: category_id)&.name || "Items"
              return render_paginated_items(items, "#{category_name} from nearby schools", page, per_page)
            end
          end
          
          # If still no items, fallback to any school
          items = with_all_associations(Item)
                  .where(main_category_id: category_id)
                  .where(deleted: false, status: 'active')
                  .where.not(id: excluded_ids)
          items = items.where.not(id: exclude_item_id) if exclude_item_id.present?
          items = apply_time_filter(items, period)
          items = apply_price_filter(items, min_price, max_price)
          items = items.order(created_at: :desc).page(page).per(per_page)
          
          if items.present?
            category_name = MainCategory.find_by(id: category_id)&.name || "Items"
            return render_paginated_items(items, "#{category_name} (from other schools)", page, per_page)
          end
          
          # Absolutely nothing found - return empty with suggestion
          return render json: {
            success: true,
            title: "No items found",
            items: [],
            pagination: {
              current_page: page.to_i,
              total_pages: 0,
              total_count: 0,
              per_page: per_page.to_i
            },
            suggestion: "Try viewing items from other categories or schools"
          }
        end
        
        # ============ ORIGINAL LOGIC (no category filter) ============
        if @current_user
          preferred_categories = UserItemView.user_preferred_categories(@current_user.id)
          
          viewed_ids = UserItemView.where(user_id: @current_user.id)
                                   .recent
                                   .pluck(:item_id)
          
          favorited_ids = Favorite.where(user_id: @current_user.id).pluck(:item_id)
          purchased_ids = PurchaseHistory.where(user_id: @current_user.id).pluck(:item_id)
          
          excluded_ids = (viewed_ids + favorited_ids + purchased_ids).uniq.first(50)
          
          if preferred_categories.any?
            items = with_all_associations(Item).where(school_id: school_id)
                        .where(main_category_id: preferred_categories)
                        .where(deleted: false, status: 'active')
                        .where.not(id: excluded_ids)
            items = items.where.not(id: exclude_item_id) if exclude_item_id.present?
            items = apply_time_filter(items, period)
            items = apply_price_filter(items, min_price, max_price)
            items = items.order(created_at: :desc).page(page).per(per_page)
            
            if items.present?
              return render_paginated_items(items, "Recommended for you", page, per_page)
            elsif nearby_ids.any?
              items = with_all_associations(Item).where(school_id: nearby_ids)
                         .where(main_category_id: preferred_categories)
                         .where(deleted: false, status: 'active')
                         .where.not(id: excluded_ids)
              
              items = apply_time_filter(items, period)
              items = apply_price_filter(items, min_price, max_price)
              items = items.order(created_at: :desc).page(page).per(per_page)
              
              if items.present?
                return render_paginated_items(items, "From nearby schools", page, per_page)
              end
            end
          end
        end
        
        items = popular_items_paginated(school_id, nearby_ids, page, per_page, period)
        items = apply_price_filter(items, min_price, max_price)
        render_paginated_items(items, "Popular items", page, per_page)
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

        # ====================== 1. SPECIFIC SUB-CATEGORY ======================
        if sub_category_id.present?
          # ✅ Use the NEW universal method that searches ALL schools
          items = get_items_by_subcategory_universal(school_id, nearby_ids, sub_category_id, page, per_page)
          items = apply_price_filter(items, min_price, max_price)

          sub = SubCategory.find_by(id: sub_category_id)
          sub_name = sub&.name || "Items"

          if items.empty?
            # Smart fallback: same main category first
            main_cat_items = get_category_items_paginated(
              school_id,
              nearby_ids,
              [sub&.main_category_id].compact,
              page,
              12
            )
            main_cat_items = apply_price_filter(main_cat_items, min_price, max_price)

            if main_cat_items.any?
              return render json: {
                success: true,
                school_id: school_id,
                message: "No items found for #{sub_name} right now",
                title: "#{sub_name} - Other items in this category",
                items: format_items(main_cat_items)
              }
            else
              # Final fallback to Accessories
              acc_items = get_category_items_paginated(
                school_id,
                nearby_ids,
                MainCategory.where(name: ['Accessories']).pluck(:id),
                page,
                8
              )
              acc_items = apply_price_filter(acc_items, min_price, max_price)

              return render json: {
                success: true,
                school_id: school_id,
                message: "No items found for #{sub_name}",
                suggestions: {
                  title: "You might like these Accessories",
                  items: format_items(acc_items)
                }
              }
            end
          end

          return render_paginated_items(items, "#{sub_name} Essentials", page, per_page)
        end

        # ====================== 2. GENERAL CATEGORY ======================
        category_map = {
          'uniforms'    => MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id),
          'sports'      => MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id),
          'accessories' => MainCategory.where(name: ['Accessories']).pluck(:id),
          'stationery'  => MainCategory.where(name: ['Stationery']).pluck(:id)
        }

        if category.present? && category_map[category].present?
          items = get_category_items_paginated(school_id, nearby_ids, category_map[category], page, per_page)
          items = apply_price_filter(items, min_price, max_price)

          if items.empty?
            # Fallback suggestions if no items found
            fallback_items = get_category_items_paginated(school_id, nearby_ids, category_map['accessories'], page, 6)
            fallback_items = apply_price_filter(fallback_items, min_price, max_price)

            return render json: {
              success: true,
              school_id: school_id,
              message: "No items found for #{category.capitalize}",
              suggestions: {
                title: "Accessories Essentials",
                items: format_items(fallback_items)
              }
            }
          end

          return render_paginated_items(items, "#{category.capitalize} Essentials", page, per_page)
        end

        # ====================== 3. FULL FALLBACK: MULTIPLE SECTIONS ======================
        all_items = []
        category_map.each do |cat_name, cat_ids|
          cat_items = get_category_items_paginated(school_id, nearby_ids, cat_ids, page, 6)
          cat_items = apply_price_filter(cat_items, min_price, max_price)
          all_items << {
            title: "#{cat_name.capitalize} Essentials",
            category: cat_name,
            items: format_items(cat_items)
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
        
        redis_key = "school:#{school_id}:trending:#{period}"
        trending_ids = $redis.zrevrange(redis_key, 0, 99)
        
        if trending_ids.any?
          items = with_all_associations(Item).where(id: trending_ids).where(deleted: false, status: 'active')
          items = apply_time_filter(items, period) if period != 'today'
          items = apply_price_filter(items, min_price, max_price)
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
        
        items = with_all_associations(Item).where(id: popular_ids).where(deleted: false, status: 'active')
        items = apply_price_filter(items, min_price, max_price)
        items = items.page(page).per(per_page)
        
        if items.present?
          render_paginated_items(items, "Trending #{period}", page, per_page)
        elsif nearby_ids.any?
          items = with_all_associations(Item).where(school_id: nearby_ids).where(deleted: false, status: 'active')
          items = apply_price_filter(items, min_price, max_price)
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
        
        items = apply_price_filter(items, min_price, max_price)
        items = items.page(page).per(per_page)
        
        title = case period
        when 'today' then "Added Today"
        when 'yesterday' then "Added Yesterday"
        when 'week' then "Added This Week"
        else "Recently Added"
        end
        
        render_paginated_items(items, title, page, per_page)
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
          items = get_recent_items_by_period(school_id, nearby_ids, period)
          items = apply_price_filter(items, min_price, max_price)
          title = period_title(period)
          
          render json: {
            success: true,
            school_id: school_id,
            title: title,
            period: period,
            items: format_items(items)
          }
        else
          sections = [
            {
              title: "Today",
              period: "today",
              items: format_items(apply_price_filter(get_recent_items_by_period(school_id, nearby_ids, 'today'), min_price, max_price))
            },
            {
              title: "Yesterday",
              period: "yesterday",
              items: format_items(apply_price_filter(get_recent_items_by_period(school_id, nearby_ids, 'yesterday'), min_price, max_price))
            },
            {
              title: "Earlier This Week",
              period: "week",
              items: format_items(apply_price_filter(get_recent_items_by_period(school_id, nearby_ids, 'week'), min_price, max_price))
            }
          ]
          
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
      
      # ================================================================
      # PRIVATE HELPERS
      # ================================================================
      
      private
      
      # ================================================================
      # 🔧 RANKING HELPER METHODS
      # ================================================================
      
      def tag_and_rank_items(items, school_id, nearby_ids)
        return [] if items.blank?
        
        nearby_ids = nearby_ids.map(&:to_i) if nearby_ids.present?
        school_id = school_id.to_i
        
        tagged = items.map do |item|
          relevance = if item.school_id == school_id
            'school_match'
          elsif nearby_ids.present? && nearby_ids.include?(item.school_id)
            'nearby_match'
          else
            'other'
          end
          
          item.define_singleton_method(:relevance) { relevance }
          item
        end
        
        tagged.sort_by do |item|
          case item.relevance
          when 'school_match' then [0, item.created_at]
          when 'nearby_match' then [1, item.created_at]
          else [2, item.created_at]
          end
        end.reverse
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
            images: item.images.map { |img| url_for(img) rescue nil }.compact,
            cover_photo: item.cover_photo,
            created_at: item.created_at.iso8601,
            view_count: item.view_count || 0
          }
        end
      end
      
      # ================================================================
      # 🔥 UNIVERSAL SEARCH METHODS (SHOW ALL ITEMS GLOBALLY)
      # ================================================================
      
      # This method searches ALL schools and ranks results:
      # 1. User's school first
      # 2. Nearby schools second  
      # 3. Other schools last
      def get_items_by_subcategory_universal(school_id, nearby_ids, sub_category_id, page = 1, per_page = 8)
        limit = per_page.to_i
        
        # STEP 1: Get items from user's school
        school_items = Item
          .where(sub_category_id: sub_category_id)
          .where(deleted: false, status: 'active')
          .where(school_id: school_id)
          .includes(
            :main_category,
            :sub_category,
            :gender,
            :item_condition,
            :brand,
            :school,
            item_variants: [:size, :color, :condition],
            images_attachments: :blob
          )
          .order(created_at: :desc)
          .limit(limit)
          .to_a
        
        school_item_ids = school_items.map(&:id)
        
        # STEP 2: Get items from nearby schools
        nearby_items = []
        if nearby_ids.any?
          nearby_items = Item
            .where(sub_category_id: sub_category_id)
            .where(deleted: false, status: 'active')
            .where(school_id: nearby_ids)
            .where.not(id: school_item_ids)
            .includes(
              :main_category,
              :sub_category,
              :gender,
              :item_condition,
              :brand,
              :school,
              item_variants: [:size, :color, :condition],
              images_attachments: :blob
            )
            .order(created_at: :desc)
            .limit(limit)
            .to_a
        end
        
        nearby_item_ids = nearby_items.map(&:id)
        
        # STEP 3: Get items from ANY school globally (UNIVERSAL FALLBACK)
        # This ensures users see ALL items, not just local ones
        global_items = Item
          .where(sub_category_id: sub_category_id)
          .where(deleted: false, status: 'active')
          .where.not(id: school_item_ids + nearby_item_ids)
          .includes(
            :main_category,
            :sub_category,
            :gender,
            :item_condition,
            :brand,
            :school,
            item_variants: [:size, :color, :condition],
            images_attachments: :blob
          )
          .order(created_at: :desc)
          .limit(limit)
          .to_a
        
        # Combine all items
        all_items = school_items + nearby_items + global_items
        
        # Return as a paginated collection (for compatibility with render_paginated_items)
        # Since we're manually combining, we wrap it in a pseudo-paginated object
        def all_items.current_page; 1; end
        def all_items.total_pages; 1; end
        def all_items.total_count; size; end
        def all_items.limit_value; size; end
        
        all_items
      end
      
      # ================================================================
      # EXISTING HELPERS
      # ================================================================
      
      def apply_price_filter(items, min_price, max_price)
        return items if min_price.nil? && max_price.nil?
        
        if items.respond_to?(:where)
          items = items.where('price >= ?', min_price) if min_price.present?
          items = items.where('price <= ?', max_price) if max_price.present?
          items
        else
          # Handle array case (from manual combination)
          filtered = items
          filtered = filtered.select { |i| i.price >= min_price } if min_price.present?
          filtered = filtered.select { |i| i.price <= max_price } if max_price.present?
          filtered
        end
      end
      
      def with_all_associations(scope)
        scope.includes(
          :main_category,
          :sub_category,
          :gender,
          :item_condition,
          :brand,
          :school,
          item_variants: [:size, :color, :condition],
          images_attachments: :blob
        )
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
          items = with_all_associations(Item)
                .where(school_id: school_id)
                .where(main_category_id: preferred_categories)
                .where(deleted: false, status: 'active')
                .where.not(id: excluded_ids)
                .joins("LEFT JOIN active_storage_attachments ON active_storage_attachments.record_id::text = items.id::text AND active_storage_attachments.record_type = 'Item'")
                .where("active_storage_attachments.id IS NOT NULL")
                .order(created_at: :desc)
                .limit(12)
                .to_a
          
          if items.count >= 4
            return format_items(items, "Based on your interests")
          elsif nearby_ids.any?
            needed = 12 - items.count
            nearby_items = with_all_associations(Item)
                          .where(school_id: nearby_ids)
                          .where(main_category_id: preferred_categories)
                          .where(deleted: false, status: 'active')
                          .where.not(id: excluded_ids)
                          .joins("LEFT JOIN active_storage_attachments ON active_storage_attachments.record_id::text = items.id::text AND active_storage_attachments.record_type = 'Item' AND active_storage_attachments.name = 'images'")
                          .where("active_storage_attachments.id IS NOT NULL")
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
          items = with_all_associations(Item).where(id: all_popular_ids).where(deleted: false, status: 'active').limit(12).to_a
          return format_items(items, "Popular at your school") if items.any?
        end
        
        if nearby_ids.any?
          nearby_items = with_all_associations(Item).where(school_id: nearby_ids).where(deleted: false, status: 'active').order(created_at: :desc).limit(12).to_a
          return format_items(nearby_items, "Popular near you") if nearby_items.any?
        end
        
        items = with_all_associations(Item).where(school_id: school_id).where(deleted: false, status: 'active').order(created_at: :desc).limit(12).to_a
        format_items(items, "Items at your school")
      end
      
     # app/controllers/api/v1/recommendations_controller.rb

# app/controllers/api/v1/recommendations_controller.rb

def school_essentials_with_fallback(school_id, nearby_ids)
  uniform_cat = MainCategory.where(name: ['Uniform', 'School Wear', 'Uniforms']).pluck(:id)
  sport_cat = MainCategory.where(name: ['Sport', 'Sports', 'Sports Gear']).pluck(:id)
  accessory_cat = MainCategory.where(name: ['Accessories']).pluck(:id)
  stationery_cat = MainCategory.where(name: ['Stationery']).pluck(:id)
  
  {
    uniforms: get_category_items(school_id, nearby_ids, uniform_cat, "Uniforms"),
    sports: get_category_items(school_id, nearby_ids, sport_cat, "Sports Gear"),
    accessories: get_category_items(school_id, nearby_ids, accessory_cat, "Accessories"),
    stationery: get_category_items(school_id, nearby_ids, stationery_cat, "Stationery")  # ✅ ADD THIS
  }
end
      
      def get_category_items(school_id, nearby_ids, category_ids, category_name)
        school_items = with_all_associations(Item).where(school_id: school_id, main_category_id: category_ids)
                           .where(deleted: false, status: 'active')
                           .order(created_at: :desc)
                           .limit(6)
                           .to_a
        
        if school_items.any?
          format_items(school_items, "School #{category_name}")
        elsif nearby_ids.any?
          nearby_items = with_all_associations(Item).where(school_id: nearby_ids, main_category_id: category_ids)
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
          items = with_all_associations(Item).where(id: trending_ids).where(deleted: false, status: 'active').to_a
          return format_items(items, "Trending today at your school") if items.any?
        end
        
        popular_ids = UserItemView.popular_in_school(school_id, 15, 2)
        items = with_all_associations(Item).where(id: popular_ids).where(deleted: false, status: 'active').to_a
        
        if items.any?
          return format_items(items, "Trending at your school")
        elsif nearby_ids.any?
          nearby_items = with_all_associations(Item).where(school_id: nearby_ids)
                             .where(deleted: false, status: 'active')
                             .order(created_at: :desc)
                             .limit(10)
                             .to_a
          return format_items(nearby_items, "Trending near you") if nearby_items.any?
        end
        
        items = with_all_associations(Item).where(school_id: school_id)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .limit(12)
                    .to_a
        
        format_items(items, "Latest at your school")
      end
      
      def recent_items_with_fallback(school_id, nearby_ids)
        items = with_all_associations(Item).where(school_id: school_id)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .limit(10)
                    .to_a
        
        if items.any?
          format_items(items, "Just added at your school")
        elsif nearby_ids.any?
          nearby_items = with_all_associations(Item).where(school_id: nearby_ids)
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
        
        items = with_all_associations(Item).where(school_id: school_id).where(deleted: false, status: 'active')
        
        if period == 'yesterday'
          items = items.where(created_at: start_time..end_time)
        else
          items = items.where('created_at > ?', start_time)
        end
        
        items = items.order(created_at: :desc).limit(10).to_a
        
        if items.any?
          format_items(items, period == 'today' ? "Added today at your school" : "Added #{period} at your school")
        elsif nearby_ids.any?
          nearby_items = with_all_associations(Item).where(school_id: nearby_ids).where(deleted: false, status: 'active')
          
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
        
        items = with_all_associations(Item).where(id: all_popular_ids).where(deleted: false, status: 'active')
        items = apply_time_filter(items, period)
        items = items.order(created_at: :desc).page(page).per(per_page)
        
        if items.present?
          items
        elsif nearby_ids.any?
          items = with_all_associations(Item).where(school_id: nearby_ids).where(deleted: false, status: 'active')
          items = apply_time_filter(items, period)
          items.order(created_at: :desc).page(page).per(per_page)
        else
          items = with_all_associations(Item).where(deleted: false, status: 'active')
          items = apply_time_filter(items, period)
          items.order(created_at: :desc).page(page).per(per_page)
        end
      end
      
      def get_category_items_paginated(school_id, nearby_ids, category_ids, page, per_page)
        items = with_all_associations(Item).where(school_id: school_id, main_category_id: category_ids)
                    .where(deleted: false, status: 'active')
                    .order(created_at: :desc)
                    .page(page)
                    .per(per_page)
        
        if items.present?
          items
        elsif nearby_ids.any?
          with_all_associations(Item).where(school_id: nearby_ids, main_category_id: category_ids)
              .where(deleted: false, status: 'active')
              .order(created_at: :desc)
              .page(page)
              .per(per_page)
        else
          with_all_associations(Item).where(main_category_id: category_ids)
              .where(deleted: false, status: 'active')
              .order(created_at: :desc)
              .page(page)
              .per(per_page)
        end
      end
      
      def get_recent_by_timeframe(school_id, nearby_ids, start_time, end_time)
        base_query = with_all_associations(Item).where(deleted: false, status: 'active')
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
        # Handle case where items is an array (from manual combination)
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
      
      # ================================================================
      # 🔥 UNIVERSAL BUILD METHODS (SHOW ALL ITEMS GLOBALLY)
      # ================================================================
      
      def build_uniform_sections_universal(school_id, nearby_ids, uniform_cat, gender, sub_category_id, min_price = nil, max_price = nil)
        # If a specific sub_category_id is requested
        if sub_category_id.present?
          sub = SubCategory.find_by(id: sub_category_id, main_category_id: uniform_cat, is_active: true)
          if sub
            items = get_items_by_subcategory_universal(school_id, nearby_ids, sub.id, 1, 8)
            items = apply_price_filter(items, min_price, max_price)
            
            return [{
              title: sub.name,
              type: "uniform_sub_category",
              sub_category_id: sub.id,
              items: format_items(items)
            }].select { |s| s[:items].any? }
          else
            return []
          end
        end

        # Build sections from all sub-categories
        SubCategory
          .where(main_category_id: uniform_cat, is_active: true)
          .order(:display_order)
          .map do |sub|
            items = get_items_by_subcategory_universal(school_id, nearby_ids, sub.id, 1, 8)
            items = apply_price_filter(items, min_price, max_price)
            
            {
              title: sub.name,
              type: "uniform_sub_category",
              sub_category_id: sub.id,
              items: format_items(items)
            }
          end
          .select { |s| s[:items].any? }
      end
      
      def build_sport_sections_universal(school_id, nearby_ids, sport_cat, sport_type, sub_category_id, min_price = nil, max_price = nil)
        # If a specific sub_category_id is requested
        if sub_category_id.present?
          sub = SubCategory.find_by(id: sub_category_id, main_category_id: sport_cat, is_active: true)
          if sub
            items = get_items_by_subcategory_universal(school_id, nearby_ids, sub.id, 1, 8)
            items = apply_price_filter(items, min_price, max_price)
            
            return [{
              title: sub.name,
              type: "sport_sub_category",
              sub_category_id: sub.id,
              items: format_items(items)
            }].select { |s| s[:items].any? }
          else
            return []
          end
        end
        
        # If a specific sport_type is requested, find by name
        if sport_type.present?
          sub = SubCategory.find_by(name: sport_type.capitalize, main_category_id: sport_cat, is_active: true)
          if sub
            items = get_items_by_subcategory_universal(school_id, nearby_ids, sub.id, 1, 8)
            items = apply_price_filter(items, min_price, max_price)
            
            return [{
              title: sub.name,
              type: "sport_sub_category",
              sub_category_id: sub.id,
              items: format_items(items)
            }].select { |s| s[:items].any? }
          else
            return []
          end
        end

        # Build sections from all sport sub-categories
        SubCategory
          .where(main_category_id: sport_cat, is_active: true)
          .order(:display_order)
          .map do |sub|
            items = get_items_by_subcategory_universal(school_id, nearby_ids, sub.id, 1, 8)
            items = apply_price_filter(items, min_price, max_price)
            
            {
              title: sub.name,
              type: "sport_sub_category",
              sub_category_id: sub.id,
              items: format_items(items)
            }
          end
          .select { |s| s[:items].any? }
      end
      
      # ================================================================
      # LEGACY METHODS (Keep for backward compatibility)
      # ================================================================
      
      def get_items_by_subcategory_paginated(school_id, nearby_ids, sub_category_id, page, per_page)
        # Redirect to universal method
        get_items_by_subcategory_universal(school_id, nearby_ids, sub_category_id, page, per_page)
      end
      
      def get_items_by_subcategory(base_query, school_id, nearby_ids, sub_category_id)
        # Legacy method - redirect to universal
        items = get_items_by_subcategory_universal(school_id, nearby_ids, sub_category_id, 1, 8)
        format_items(items)
      end
      
      def format_items(items, reason = nil)
        return [] if items.blank?
        
        # Normalize: ensure we have ActiveRecord objects
        normalized = items.map do |item|
          case item
          when Item
            item
          when Hash
            id = item["id"] || item[:id]
            id.present? ? Item.find_by(id: id) : nil
          else
            nil
          end
        end.compact
        
        return [] if normalized.empty?
        
        eager_loaded = Item.where(id: normalized.map(&:id))
                           .includes(
                             :main_category,
                             :sub_category,
                             :gender,
                             :item_condition,
                             :brand,
                             :school,
                             item_variants: [:size, :color, :condition],
                             images_attachments: :blob
                           )
                           .to_a
        
        eager_loaded.map do |item|
          primary_variant = item.item_variants.find(&:is_active?)
          actual_price = primary_variant&.price&.to_f || item.price.to_f
          actual_quantity = primary_variant&.quantity || item.available_quantity || item.total_quantity || 0
          
          {
            id: item.id.to_s,
            name: item.name.to_s.truncate(50),
            description: item.description.to_s.truncate(80),
            price: actual_price,
            view_count: item.view_count || 0,
            image: item.cover_photo,
            school_id: item.school_id,
            school: item.school&.name,
            category: item.main_category&.name,
            main_category_id: item.main_category_id,
            sub_category_id: item.sub_category_id,
            gender: item.gender&.name,
            gender_id: item.gender_id,
            reason: reason,
            created_at: item.created_at,
            size_name: primary_variant&.size&.name || item.try(:size_name),
            color_name: primary_variant&.color&.name || item.try(:color_name),
            condition_name: primary_variant&.condition&.name || item.item_condition&.name,
            brand_name: item.brand&.name,
            available_quantity: actual_quantity,
            images: item.all_image_urls,
            cover_photo: item.cover_photo
          }
        end.compact
      end
    end
  end
end