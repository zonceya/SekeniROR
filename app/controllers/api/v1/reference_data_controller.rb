module Api
  module V1
    class ReferenceDataController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # GET /api/v1/all_reference_data
      def index
        # Cache key for 1 hour - reference data rarely changes
        cache_key = "api/v1/all_reference_data"
        
        # Try to get from cache first
        cached_data = Rails.cache.read(cache_key)
        
        if cached_data
          Rails.logger.info "Serving reference data from CACHE (0 queries)"
          return render json: cached_data
        end
        
        Rails.logger.info "Cache MISS - loading reference data from database"
        
        # Eager load sub_categories
        main_categories = MainCategory.active
                                      .ordered
                                      .includes(:sub_categories)
        
        # Eager load province for schools
        schools = School.limit(50).includes(:province)
        
        response_data = {
          success: true,
          data: {
            main_categories: main_categories.map { |cat|
              {
                id: cat.id,
                name: cat.name,
                description: cat.description,
                icon_name: cat.icon_name,
                display_order: cat.display_order,
                sub_categories: cat.sub_categories
                                  .select { |sub| sub.is_active == true }
                                  .sort_by { |sub| [sub.display_order, sub.id] }
                                  .map { |sub|
                  {
                    id: sub.id,
                    name: sub.name,
                    description: sub.description,
                    display_order: sub.display_order
                  }
                }
              }
            },
            colors: ItemColor.all.map { |c| { id: c.id, name: c.name } },
            sizes: ItemSize.all.map { |s| { id: s.id, name: s.name } },
            brands: Brand.all.map { |b| { id: b.id, name: b.name } },
            conditions: ItemCondition.all.map { |c| { id: c.id, name: c.name, description: c.description } },
            provinces: Province.all.order(:name).map { |p| { id: p.id, name: p.name } },
            towns: Town.all.map { |t| { id: t.id, name: t.name, province_id: t.province_id } },
            schools: schools.map { |s| 
              {
                id: s.id,
                name: s.name,
                province_id: s.province_id,
                province: s.province ? { id: s.province.id, name: s.province.name } : nil
              }
            },
            genders: Gender.where(category: 'standard').order(:id).map { |g| 
              { 
                id: g.id, 
                name: g.name, 
                display_name: g.display_name 
              } 
            },
            tags: Tag.all.map { |t| { id: t.id, name: t.name, tag_type: t.tag_type } },
            locations: Location.all.map { |l| 
              { 
                id: l.id, 
                province: l.province,
                state_or_region: l.state_or_region,
                country: l.country,
                town_id: l.town_id,
                name: [l.province, l.state_or_region, l.country].compact.join(', ')
              } 
            }
          }
        }
        
        # Store in cache for 1 hour
        Rails.cache.write(cache_key, response_data, expires_in: 1.hour)
        
        render json: response_data
      end
    end
  end
end