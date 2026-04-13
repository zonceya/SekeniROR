# app/controllers/api/v1/filters_controller.rb

module Api
  module V1
    class FiltersController < ApplicationController
      include Authenticatable
      
      # GET /api/v1/categories/:id/filter_config
      def category_filter_config
        category = MainCategory.find(params[:id])
        
        filter_groups = []
        
        # 1. Condition filter (always show)
        filter_groups << condition_filter
        
        # 2. Gender filter (only for categories that have gender)
        if has_gender_filter?(category)
          filter_groups << gender_filter(category)
        end
        
        # 3. Size/Age filter (only for categories that have size)
        # Always add size filter for these categories, even if empty
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
        
        render json: {
          success: true,
          category_id: category.id,
          category_name: category.name,
          filter_groups: filter_groups
        }
      end
      
      # GET /api/v1/filters/options
      def options
        render json: {
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
      end
      
      # GET /api/v1/filters/categories
      def categories
        categories = MainCategory.active.map do |cat|
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
        
        render json: { success: true, categories: categories }
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
        genders = if params[:phase].present?
                    Gender.where(category: params[:phase])
                  else
                    Gender.all
                  end
        
        render json: {
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
      end
      
      # GET /api/v1/filters/conditions
      def conditions
        render json: {
          success: true,
          conditions: ItemCondition.all.map { |c| { id: c.id, name: c.name, description: c.description } }
        }
      end
      
      # GET /api/v1/filters/colors
      def colors
        render json: {
          success: true,
          colors: ItemColor.all.map { |c| { id: c.id, name: c.name } }
        }
      end
      
      # GET /api/v1/filters/sizes
      def sizes
        render json: {
          success: true,
          sizes: ItemSize.all.map { |s| { id: s.id, name: s.name } }
        }
      end
      
      # GET /api/v1/filters/brands?category_id=1
      def brands
        if params[:category_id].present?
          brand_ids = Item.where(main_category_id: params[:category_id])
                          .where.not(brand_id: nil)
                          .pluck(:brand_id)
                          .uniq
          brands = Brand.where(id: brand_ids)
        else
          brands = Brand.all
        end
        
        render json: {
          success: true,
          brands: brands.map { |b| { id: b.id, name: b.name } }
        }
      end
      
      # GET /api/v1/filters/tags
      def tags
        tags = if params[:type].present?
                 Tag.where(tag_type: params[:type])
               else
                 Tag.all
               end
        
        render json: {
          success: true,
          tags: tags.map { |t| { id: t.id, name: t.name, type: t.tag_type } }
        }
      end
   
# GET /api/v1/filters/global_config
def global_filter_config
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
  # Get global min and max prices from all items
  global_min_price = ItemVariant
    .joins(:item)
    .where.not(item_variants: { price: nil })
    .minimum('item_variants.price')
  
  global_max_price = ItemVariant
    .joins(:item)
    .where.not(item_variants: { price: nil })
    .maximum('item_variants.price')
  
  # Fallback to items table if no variants found
  if global_min_price.nil? || global_max_price.nil?
    global_min_price = Item.where.not(price: nil).minimum(:price)
    global_max_price = Item.where.not(price: nil).maximum(:price)
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
  
  render json: {
    success: true,
    filter_groups: filter_groups
  }
end
      private
      
      def condition_filter
        {
          id: "condition",
          name: "Condition",
          filter_type: "single_select",
          options: ItemCondition.all.map { |c| 
            { id: c.id, name: c.name }
          }
        }
      end
      
      def gender_filter(category)
        genders = if category.name == 'Footwear'
          Gender.where(gender_group: ['boys', 'girls', 'unisex'])
        else
          Gender.where(gender_group: ['boys', 'girls'])
        end
        
        {
          id: "gender",
          name: "Gender",
          filter_type: "single_select",
          options: genders.map { |g| 
            { id: g.id, name: g.display_name }
          }
        }
      end
      
      def size_filter(category)
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
        
        {
          id: "size",
          name: "Size / Age",
          filter_type: "single_select",
          options: sizes.map { |s| 
            { id: s.id, name: s.name }
          }
        }
      end
      
      def grade_filter
        # Get grades from genders table
        grades = Gender.where(category: ['foundation', 'intermediate', 'senior', 'fet'])
                        .where(gender_group: 'all')
                        .order(:id)
        
        {
          id: "grade",
          name: "Grade",
          filter_type: "single_select",
          options: grades.map { |g| 
            { id: g.id, name: g.display_name }
          }
        }
      end
      
      def type_filter(category)
        {
          id: "type",
          name: "Type",
          filter_type: "multi_select",
          options: category.sub_categories.active.map { |sub| 
            { id: sub.id, name: sub.name }
          }
        }
      end
      
      def sport_type_filter
        sport_category = MainCategory.find_by(name: 'Sport')
        
        {
          id: "sport_type",
          name: "Sport Type",
          filter_type: "single_select",
          options: sport_category.sub_categories.active.map { |sub| 
            { id: sub.id, name: sub.name }
          }
        }
      end
      
      def brand_filter(category)
        brand_ids = Item.where(main_category_id: category.id)
                        .where.not(brand_id: nil)
                        .distinct
                        .pluck(:brand_id)
        
        brands = Brand.where(id: brand_ids)
        
        {
          id: "brand",
          name: "Brand",
          filter_type: "multi_select",
          options: brands.map { |b| 
            { id: b.id, name: b.name }
          }
        }
      end
      
      def color_filter(category)
        # Query through ItemVariant to get color_ids
        color_ids = ItemVariant
          .joins(:item)
          .where(items: { main_category_id: category.id })
          .where.not(item_variants: { color_id: nil })
          .distinct
          .pluck(:color_id)
        
        colors = ItemColor.where(id: color_ids)
        
        {
          id: "color",
          name: "Color",
          filter_type: "multi_select",
          options: colors.map { |c| 
            { id: c.id, name: c.name }
          }
        }
      end
      
      def price_filter(category)
        # Get min price from item_variants
        min_price = ItemVariant
          .joins(:item)
          .where(items: { main_category_id: category.id })
          .where.not(item_variants: { price: nil })
          .minimum('item_variants.price')
        
        # Get max price from item_variants
        max_price = ItemVariant
          .joins(:item)
          .where(items: { main_category_id: category.id })
          .where.not(item_variants: { price: nil })
          .maximum('item_variants.price')
        
        # If no prices found in variants, try items table
        if min_price.nil? || max_price.nil?
          min_price = Item
            .where(main_category_id: category.id)
            .where.not(price: nil)
            .minimum(:price)
          
          max_price = Item
            .where(main_category_id: category.id)
            .where.not(price: nil)
            .maximum(:price)
        end
        
        # If still no prices found, return default range
        if min_price.nil? || max_price.nil?
          return {
            id: "price",
            name: "Price Range",
            filter_type: "slider",
            min: 0,
            max: 500,
            step: 10
          }
        end
        
        # Convert to integers and round
        min_price = min_price.to_f.round
        max_price = max_price.to_f.round
        
        # Ensure min is less than max
        if min_price >= max_price
          max_price = min_price + 100
        end
        
        {
          id: "price",
          name: "Price Range",
          filter_type: "slider",
          min: min_price,
          max: max_price,
          step: 10
        }
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