module Api
  module V1
    class LocationsController < ApplicationController
      def index
        if params[:province_id]
          render json: Location.where(province_id: params[:province_id]).select(:id, :name, :province_id)
        else
          render json: Location.select(:id, :name, :province_id)
        end
      end
    end
  end
end