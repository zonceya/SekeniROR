# app/controllers/api/v1/filters_controller.rb

module Api
  module V1
    class FiltersController < ApplicationController
      include Authenticatable
      
      # GET /api/v1/categories/:id/filter_config
      def category_filter_config
        category_id = params[:id]
        cache_key = "filter_config_category_#{category_id}"
        
        # Try to get from cache first
        cached = Rails.cache.read(cache_key)
        if cached
          Rails.logger.info "Serving filter config from CACHE for category #{category_id}"
          return render json: cached
        end
        
        Rails.logger.info "Cache MISS - loading filter config for category #{category_id}"
        category = MainCategory.find(category_id)
        
        filter_groups = []
        
        # 1. Condition filter (always show)
        filter_groups << condition_filter
        
        # 2. Gender filter (only for categories that have gender)
        if has_gender_filter?(category)
          filter_groups << gender_filter(category)
        end
        
        # 3. Size/Age filter (only for categories that have size)
        if has_size_filter?(category)
          filter_groups << size_filter(category)
        end
        
        # 4. Grade filter (special for textbooks)
        if category.name == 'Textbooks'
          filter_groups << grade_filter
        end
        
        # 5. Type filter (from subcategories)
        if category.sub_categories.active.any?
          filter_groups << type_filter(category)
        end
        
        # 6. Sport Type filter (special for sport)
        if category.name == 'Sport'
          filter_groups << sport_type_filter
        end
        
        # 7. Brand filter
        brand_group = brand_filter(category)
        filter_groups << brand_group if brand_group[:options].present?
        
        # 8. Color filter (only for applicable categories)
        if has_color_filter?(category)
          color_group = color_filter(category)
          filter_groups << color_group if color_group[:options].present?
        end
        
        # 9. Price filter (always)
        filter_groups << price_filter(category)
        
        response_data = {
          success: true,
          category_id: category.id,
          category_name: category.name,
          filter_groups: filter_groups
        }
        
        # Cache for 1 hour
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        
        render json: response_data
      end
      
      # GET /api/v1/filters/options
      def options
        cache_key = "filters_all_options"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        response_data = {
          success: true,
          data: {
            categories: MainCategory.active.pluck(:id, :name),
            conditions: ItemCondition.all.pluck(:id, :name),
            colors: ItemColor.all.pluck(:id, :name),
            sizes: ItemSize.all.pluck(:id, :name),
            brands: Brand.all.pluck(:id, :name),
            genders: Gender.all.pluck(:id, :name, :display_name)
          }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/categories
      def categories
        cache_key = "filters_categories_with_subcategories"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        categories = MainCategory.active.includes(:sub_categories).map do |cat|
          {
            id: cat.id,
            name: cat.name,
            icon: cat.icon_name,
            subcategories: cat.sub_categories.active.map do |sub|
              {
                id: sub.id,
                name: sub.name
              }
            end
          }
        end
        
        response_data = { success: true, categories: categories }
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/subcategories?category_id=1
      def subcategories
        category = MainCategory.find(params[:category_id])
        subcategories = category.sub_categories.active
        
        render json: {
          success: true,
          category: category.name,
          subcategories: subcategories.map { |s| { id: s.id, name: s.name } }
        }
      end
      
      # GET /api/v1/filters/genders?phase=foundation
      def genders
        cache_key = "filters_genders_#{params[:phase].presence || 'all'}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        genders = if params[:phase].present?
                    Gender.where(category: params[:phase])
                  else
                    Gender.all
                  end
        
        response_data = {
          success: true,
          genders: genders.map { |g| 
            { 
              id: g.id, 
              name: g.name, 
              display_name: g.display_name,
              category: g.category,
              gender_group: g.gender_group
            } 
          }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/conditions
      def conditions
        cache_key = "filters_conditions"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        response_data = {
          success: true,
          conditions: ItemCondition.all.map { |c| { id: c.id, name: c.name, description: c.description } }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/colors
      def colors
        cache_key = "filters_colors"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        response_data = {
          success: true,
          colors: ItemColor.all.map { |c| { id: c.id, name: c.name } }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/sizes
      def sizes
        cache_key = "filters_sizes"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        response_data = {
          success: true,
          sizes: ItemSize.all.map { |s| { id: s.id, name: s.name } }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/brands?category_id=1
      def brands
        cache_key = "filters_brands_#{params[:category_id].presence || 'all'}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        if params[:category_id].present?
          brand_ids = Item.where(main_category_id: params[:category_id])
                          .where.not(brand_id: nil)
                          .pluck(:brand_id)
                          .uniq
          brands = Brand.where(id: brand_ids)
        else
          brands = Brand.all
        end
        
        response_data = {
          success: true,
          brands: brands.map { |b| { id: b.id, name: b.name } }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
      
      # GET /api/v1/filters/tags
      def tags
        cache_key = "filters_tags_#{params[:type].presence || 'all'}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return render json: cached
        end
        
        tags = if params[:type].present?
                 Tag.where(tag_type: params[:type])
               else
                 Tag.all
               end
        
        response_data = {
          success: true,
          tags: tags.map { |t| { id: t.id, name: t.name, type: t.tag_type } }
        }
        
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        render json: response_data
      end
   
      # GET /api/v1/filters/global_config
      def global_filter_config
        cache_key = "filters_global_config"
        cached = Rails.cache.read(cache_key)
        
        if cached
          Rails.logger.info "Serving global filter config from CACHE"
          return render json: cached
        end
        
        Rails.logger.info "Cache MISS - loading global filter config"
        filter_groups = []
        
        # 1. Category filter (for selecting which category to filter by)
        filter_groups << {
          id: "category",
          name: "Category",
          filter_type: "single_select",
          options: MainCategory.active.map { |cat| 
            { id: cat.id, name: cat.name }
          }
        }
        
        # 2. Condition filter (always show)
        filter_groups << {
          id: "condition",
          name: "Condition",
          filter_type: "single_select",
          options: ItemCondition.all.map { |c| 
            { id: c.id, name: c.name }
          }
        }
        
        # 3. Price filter (global across all items)
        # FIXED: Use raw SQL to avoid ORDER BY issues like in price_filter
        sql = """
          SELECT 
            MIN(item_variants.price) as min_price, 
            MAX(item_variants.price) as max_price
          FROM item_variants
          INNER JOIN items ON items.id = item_variants.item_id
          WHERE item_variants.price IS NOT NULL
        """
        
        result = ActiveRecord::Base.connection.execute(sql).first
        global_min_price = result['min_price']
        global_max_price = result['max_price']
        
        # Fallback to items table if no variants found
        if global_min_price.nil? || global_max_price.nil?
          sql = """
            SELECT MIN(price) as min_price, MAX(price) as max_price
            FROM items
            WHERE price IS NOT NULL
          """
          result = ActiveRecord::Base.connection.execute(sql).first
          global_min_price = result['min_price']
          global_max_price = result['max_price']
        end
        
        # If still no prices, use default
        if global_min_price.nil? || global_max_price.nil?
          global_min_price = 0
          global_max_price = 500
        end
        
        filter_groups << {
          id: "price",
          name: "Price Range",
          filter_type: "slider",
          min: global_min_price.to_f.round,
          max: global_max_price.to_f.round,
          step: 10
        }
        
        response_data = {
          success: true,
          filter_groups: filter_groups
        }
        
        # Cache for 1 hour
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        
        render json: response_data
      end
      
      private
      
      def condition_filter
        cache_key = "filter_condition_options"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        result = {
          id: "condition",
          name: "Condition",
          filter_type: "single_select",
          options: ItemCondition.all.map { |c| 
            { id: c.id, name: c.name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def gender_filter(category)
        cache_key = "filter_gender_#{category.id}_#{category.name}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        genders = if category.name == 'Footwear'
          Gender.where(gender_group: ['boys', 'girls', 'unisex'])
        else
          Gender.where(gender_group: ['boys', 'girls'])
        end
        
        result = {
          id: "gender",
          name: "Gender",
          filter_type: "single_select",
          options: genders.map { |g| 
            { id: g.id, name: g.display_name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def size_filter(category)
        cache_key = "filter_size_#{category.id}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        # Query through ItemVariant to get size_ids
        size_ids = ItemVariant
          .joins(:item)
          .where(items: { main_category_id: category.id })
          .where.not(item_variants: { size_id: nil })
          .distinct
          .pluck(:size_id)
        
        sizes = ItemSize.where(id: size_ids)
        
        # For Uniforms and Sport, filter to age-based sizes
        if ['Uniforms', 'Sport'].include?(category.name)
          age_based_sizes = sizes.select { |s| s.name.include?('years') || s.name.match?(/Grade|youth/i) }
          sizes = age_based_sizes if age_based_sizes.any?
        end
        
        # For Footwear, filter to shoe sizes
        if category.name == 'Footwear'
          shoe_sizes = sizes.select { |s| s.name.match?(/Kids|Youth|Adult|[0-9]/) && !s.name.include?('years') }
          sizes = shoe_sizes if shoe_sizes.any?
        end
        
        result = {
          id: "size",
          name: "Size / Age",
          filter_type: "single_select",
          options: sizes.map { |s| 
            { id: s.id, name: s.name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def grade_filter
        cache_key = "filter_grade_options"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        # Get grades from genders table
        grades = Gender.where(category: ['foundation', 'intermediate', 'senior', 'fet'])
                        .where(gender_group: 'all')
                        .order(:id)
        
        result = {
          id: "grade",
          name: "Grade",
          filter_type: "single_select",
          options: grades.map { |g| 
            { id: g.id, name: g.display_name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def type_filter(category)
        cache_key = "filter_type_#{category.id}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        result = {
          id: "type",
          name: "Type",
          filter_type: "multi_select",
          options: category.sub_categories.active.map { |sub| 
            { id: sub.id, name: sub.name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def sport_type_filter
        cache_key = "filter_sport_type"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        sport_category = MainCategory.find_by(name: 'Sport')
        
        result = {
          id: "sport_type",
          name: "Sport Type",
          filter_type: "single_select",
          options: sport_category.sub_categories.active.map { |sub| 
            { id: sub.id, name: sub.name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def brand_filter(category)
        cache_key = "filter_brand_#{category.id}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        brand_ids = Item.where(main_category_id: category.id)
                        .where.not(brand_id: nil)
                        .distinct
                        .pluck(:brand_id)
        
        brands = Brand.where(id: brand_ids).order(:name)
        
        result = {
          id: "brand",
          name: "Brand",
          filter_type: "multi_select",
          options: brands.map { |b| 
            { id: b.id, name: b.name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def color_filter(category)
        cache_key = "filter_color_#{category.id}"
        cached = Rails.cache.read(cache_key)
        
        if cached
          return cached
        end
        
        # Query through ItemVariant to get color_ids
        color_ids = ItemVariant
          .joins(:item)
          .where(items: { main_category_id: category.id })
          .where.not(item_variants: { color_id: nil })
          .distinct
          .pluck(:color_id)
        
        colors = ItemColor.where(id: color_ids).order(:name)
        
        result = {
          id: "color",
          name: "Color",
          filter_type: "multi_select",
          options: colors.map { |c| 
            { id: c.id, name: c.name }
          }
        }
        
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        result
      end
      
      def price_filter(category)
       cache_key = "filter_price_#{category.id}"
       cached = Rails.cache.read(cache_key)
  
         if cached
         return cached
        end
  
          # FIXED: Get min and max in ONE query - NO ORDER BY clause
          # Use find_by_sql to avoid Rails automatically adding ORDER BY
          sql = """
            SELECT 
              MIN(item_variants.price) as min_price, 
              MAX(item_variants.price) as max_price
            FROM item_variants
            INNER JOIN items ON items.id = item_variants.item_id
            WHERE items.main_category_id = #{category.id.to_i}
            AND item_variants.price IS NOT NULL
          """
  
  result = ActiveRecord::Base.connection.execute(sql).first
  min_price = result['min_price']
  max_price = result['max_price']
  
  # If no prices found in variants, try items table
  if min_price.nil? || max_price.nil?
    sql = """
      SELECT MIN(price) as min_price, MAX(price) as max_price
      FROM items
      WHERE main_category_id = #{category.id.to_i}
      AND price IS NOT NULL
    """
    result = ActiveRecord::Base.connection.execute(sql).first
    min_price = result['min_price']
    max_price = result['max_price']
  end
  
  # If still no prices found, return default range
  if min_price.nil? || max_price.nil?
    result = {
      id: "price",
      name: "Price Range",
      filter_type: "slider",
      min: 0,
      max: 500,
      step: 10
    }
    Rails.cache.write(cache_key, result, expires_in: 1.hour)
    return result
  end
  
  # Convert to integers and round
  min_price = min_price.to_f.round
  max_price = max_price.to_f.round
  
  # Ensure min is less than max
  if min_price >= max_price
    max_price = min_price + 100
  end
  
  result = {
    id: "price",
    name: "Price Range",
    filter_type: "slider",
    min: min_price,
    max: max_price,
    step: 10
  }
  
  Rails.cache.write(cache_key, result, expires_in: 1.hour)
  result
end
      
      def has_gender_filter?(category)
        ['Uniforms', 'Sport', 'Footwear'].include?(category.name)
      end
      
      def has_size_filter?(category)
        ['Uniforms', 'Sport', 'Footwear'].include?(category.name)
      end
      
      def has_color_filter?(category)
        ['Uniforms', 'Sport', 'Footwear', 'Stationery', 'Accessories'].include?(category.name)
      end
    end
  end
end