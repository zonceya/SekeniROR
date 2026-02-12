module Api
  module V1
    class GendersController < ApplicationController
      def index
        genders = Gender.select(:id, :name, :display_name)
                       .where(category: 'standard')
                       .order(:id)
        render json: genders
      end
    end
  end
end