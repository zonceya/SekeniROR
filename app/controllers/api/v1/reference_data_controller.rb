module Api
  module V1
    class ReferenceDataController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # GET /api/v1/all_reference_data
      def index
        render json: {
          success: true,
          data: {
            main_categories: MainCategory.active.ordered.map { |cat|
              {
                id: cat.id,
                name: cat.name,
                description: cat.description,
                icon_name: cat.icon_name,
                display_order: cat.display_order,
                item_types: cat.item_types.active.map { |type|
                  {
                    id: type.id,
                    name: type.name,
                    description: type.description,
                    group_id: type.group_id
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
            schools: School.limit(50).map { |s| 
              {
                id: s.id,
                name: s.name,
                province_id: s.province_id,
                province: {
                  id: s.province.id,
                  name: s.province.name
                }
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
      end
    end
  end
end