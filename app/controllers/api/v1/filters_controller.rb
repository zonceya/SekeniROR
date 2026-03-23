# app/controllers/api/v1/filters_controller.rb
module Api
  module V1
    class FiltersController < ApplicationController
      include Authenticatable
      
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
      
      # GET /api/v1/filters/brands
      # In app/controllers/api/v1/filters_controller.rb

# GET /api/v1/filters/brands?category_id=1
   # GET /api/v1/filters/brands
def brands
  if params[:category_id].present?
    # FIXED: Direct query without joins
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
    end
  end
end