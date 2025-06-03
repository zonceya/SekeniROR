module Api
  module V1
    class TagsController < ApplicationController
      def index
        tags = if params[:tag_type].present?
                 Tag.where(tag_type: params[:tag_type])
               else
                 Tag.all
               end

        render json: tags.select(:id, :name, :tag_type)
      end
    end
  end
end

