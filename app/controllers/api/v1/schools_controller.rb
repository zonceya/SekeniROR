module Api
  module V1
    class SchoolsController < ApplicationController
      def index
        if params[:province_id]
          render json: School.where(province_id: params[:province_id]).select(:id, :name, :province_id)
        else
          render json: School.select(:id, :name, :province_id)
        end
      end
    end
  end
end
