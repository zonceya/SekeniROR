module Api
  module V1
    class ItemColorsController < ApplicationController
      def index
        render json: ItemColor.select(:id, :name)
      end
    end
  end
end