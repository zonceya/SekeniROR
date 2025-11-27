# app/controllers/api/v1/provinces_controller.rb
module Api
  module V1
    class ProvincesController < ApplicationController
      def index
        provinces = Province.select(:id, :name).order(:name)
        render json: provinces
      end
    end
  end
end