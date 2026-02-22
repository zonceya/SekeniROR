module Api
  module V1
    class LocationsController < ApplicationController
      def index
        if params[:province_name]
          locations = Location.where(province: params[:province_name])
        else
          locations = Location.all
        end

        result = locations.map do |location|
          {
            id: location.id,
            name: [location.province, location.state_or_region, location.country].compact.join(', '),
            province: location.province,
            state_or_region: location.state_or_region,
            country: location.country,
            town_id: location.town_id
          }
        end

        render json: result
      end
    end
  end
end