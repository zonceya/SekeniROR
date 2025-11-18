# app/controllers/api/v1/card_validation_controller.rb
module Api
  module V1
    class CardValidationController < ApplicationController
      # Skip CSRF protection for API endpoints
      skip_before_action :verify_authenticity_token
      
      def validate
        card_number = params[:card_number]

        if card_number.blank?
          return render json: { error: "Card number is required" }, status: :unprocessable_entity
        end

        result = CardValidationService.validate_card(card_number)

        render json: {
          card_number: card_number,
          validation_result: result
        }
      end
    end
  end
end