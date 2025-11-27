module Api
  module V1
    class ItemSizesController < ApplicationController
      def index
        render json: ItemSize.select(:id, :name)
      end
    end
  end
end