module Api
  module V1
    class ItemConditionsController < ApplicationController
      def index
        render json: ItemCondition.select(:id, :name)
      end
    end
  end
end