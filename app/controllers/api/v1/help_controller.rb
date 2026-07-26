# app/controllers/api/v1/help_controller.rb
module Api
  module V1
    class HelpController < ApplicationController
      before_action :authenticate_user
      skip_before_action :verify_authenticity_token

      def send_support_request
        subject = params[:subject]
        description = params[:description]

        # Validate
        if subject.blank?
          return render json: { 
            success: false, 
            message: "Subject is required" 
          }, status: :bad_request
        end

        if description.blank?
          return render json: { 
            success: false, 
            message: "Description is required" 
          }, status: :bad_request
        end

        if description.length > 400
          return render json: { 
            success: false, 
            message: "Description cannot exceed 400 characters" 
          }, status: :bad_request
        end

        # ✅ ACTUALLY SEND THE EMAIL
        HelpMailer.support_request(@current_user, subject, description).deliver_now

        # ✅ Send auto-reply to user
        HelpMailer.auto_reply(@current_user, subject).deliver_now

        render json: {
          success: true,
          message: "Support request sent successfully! We'll get back to you within 24 hours."
        }, status: :ok
      end

      def status
        render json: {
          success: true,
          status: "operational",
          support_email: "admin@skoolswap.co.za",
          response_time: "Within 24 hours",
          phone: "075 051 0169",
          availability: {
            weekdays: "Monday - Friday, 08:00 - 17:00",
            public_holidays: "10:00 - 13:00",
            exceptions: "Closed on Christmas Day and New Year's Day"
          }
        }, status: :ok
      end

      private

      def authenticate_user
        token = request.headers["Authorization"]&.split(" ")&.last

        if token.blank?
          return render json: { 
            success: false, 
            message: "Authorization token required" 
          }, status: :unauthorized
        end

        session = UserSession.find_by(token: token)

        if session.nil? || session.expired?
          return render json: { 
            success: false, 
            message: "Invalid or expired token" 
          }, status: :unauthorized
        end

        if session.user.deleted? || !session.user.status?
          return render json: { 
            success: false, 
            message: "Account is inactive" 
          }, status: :forbidden
        end

        @current_user = session.user
      end
    end
  end
end