module Api
  module V1
    class ItemTypesController < ApplicationController
      def index
        render json: ItemType.select(:id, :name, :description)
      end
    end
  end
end

