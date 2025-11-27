# app/controllers/api/v1/towns_controller.rb
module Api
  module V1
    class TownsController < ApplicationController
      def index
        towns = Town.select(:id, :name, :province_id).order(:name)
        towns = towns.where(province_id: params[:province_id]) if params[:province_id]
        render json: towns
      end
    end
  end
end