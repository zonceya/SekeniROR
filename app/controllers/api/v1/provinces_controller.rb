module Api
  module V1
    class ProvincesController < ApplicationController
      def index
        render json: Province.select(:id, :name)
      end
    end
  end
end

