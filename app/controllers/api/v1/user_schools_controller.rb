# app/controllers/api/v1/user_schools_controller.rb
module Api
  module V1
    class UserSchoolsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user
      before_action :set_user_school, only: [:update, :destroy]

      # GET /api/v1/user_schools/current
      def current
        user_school = @current_user.current_school_mapping
        
        if user_school
          render json: {
            school_mapped: true,
            school: {
              id: user_school.school_id,
              name: user_school.school.name,
              province_id: user_school.school.province_id,
              location_id: user_school.school.location_id,
              school_type: user_school.school.school_type,
              mapping_id: user_school.id,
              mapped_at: user_school.created_at,
              updated_at: user_school.updated_at
            }
          }, status: :ok
        else
          render json: {
            school_mapped: false,
            school: nil
          }, status: :ok
        end
      end

      # POST /api/v1/user_schools
      def create
        Rails.logger.info "📚 Creating school mapping for user #{@current_user.id}"

        # Check if user already has a school
        if @current_user.school_mapped?
          existing = @current_user.current_school_mapping
          
          return render json: {
            error: "User already has a school mapped. Use UPDATE to change schools.",
            school_mapped: true,
            school: {
              id: existing.school_id,
              name: existing.school.name,
              mapping_id: existing.id,
              mapped_at: existing.created_at
            }
          }, status: :unprocessable_entity
        end

        # Validate school_id parameter
        unless params[:school_id].present?
          return render json: {
            error: "School ID is required"
          }, status: :bad_request
        end

        # Find the school
        school = School.find_by(id: params[:school_id])
        unless school
          Rails.logger.error "❌ School not found with ID: #{params[:school_id]}"
          
          return render json: {
            error: "School not found"
          }, status: :not_found
        end

        # Create the mapping
        user_school = UserSchool.new(
          user_id: @current_user.id,
          school_id: school.id
        )

        if user_school.save
          Rails.logger.info "✅ School mapped successfully for user #{@current_user.id} to #{school.name}"
          
          # Clear cache
          clear_user_cache
          
          render json: {
            success: true,
            message: "School mapped successfully",
            school_mapped: true,
            school: school_response(user_school)
          }, status: :created
        else
          Rails.logger.error "❌ Failed to save school mapping: #{user_school.errors.full_messages}"
          
          render json: {
            error: "Failed to map school",
            details: user_school.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/user_schools/:id
      def update
        Rails.logger.info "📚 Updating school mapping #{@user_school.id} for user #{@current_user.id}"

        # Validate school_id parameter
        unless params[:school_id].present?
          return render json: {
            error: "School ID is required"
          }, status: :bad_request
        end

        # Find the new school
        school = School.find_by(id: params[:school_id])
        unless school
          Rails.logger.error "❌ School not found with ID: #{params[:school_id]}"
          
          return render json: {
            error: "School not found"
          }, status: :not_found
        end

        # Update the mapping
        if @user_school.update(school_id: school.id)
          Rails.logger.info "✅ School updated successfully for user #{@current_user.id} to #{school.name}"
          
          # Clear cache
          clear_user_cache
          
          render json: {
            success: true,
            message: "School updated successfully",
            school_mapped: true,
            school: school_response(@user_school.reload)
          }, status: :ok
        else
          Rails.logger.error "❌ Failed to update school mapping: #{@user_school.errors.full_messages}"
          
          render json: {
            error: "Failed to update school",
            details: @user_school.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/user_schools/:id
      def destroy
        Rails.logger.info "📚 Removing school mapping #{@user_school.id} for user #{@current_user.id}"
        
        school_name = @user_school.school.name
        
        if @user_school.destroy
          Rails.logger.info "✅ School mapping removed for user #{@current_user.id} from #{school_name}"
          
          # Clear cache
          clear_user_cache
          
          render json: {
            success: true,
            message: "School mapping removed successfully",
            school_mapped: false
          }, status: :ok
        else
          Rails.logger.error "❌ Failed to remove school mapping"
          
          render json: {
            error: "Failed to remove school mapping"
          }, status: :unprocessable_entity
        end
      end

      private

      def set_user_school
        @user_school = UserSchool.find_by(id: params[:id])
        
        unless @user_school
          return render json: { 
            error: "School mapping not found" 
          }, status: :not_found
        end

        # Security check - ensure user owns this mapping
        if @user_school.user_id != @current_user.id
          return render json: { 
            error: "Unauthorized to modify this mapping" 
          }, status: :forbidden
        end
      end

      def authenticate_user
        token = request.headers["Authorization"]&.split(" ")&.last
        
        unless token
          return render json: { error: "Authorization token required" }, status: :unauthorized
        end

        session = UserSession.find_by(token: token)

        if session && !session.user.deleted?
          @current_user = session.user
          Rails.logger.debug "✅ Authenticated user: #{@current_user.id}"
        else
          Rails.logger.warn "❌ Invalid or expired token"
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def school_response(user_school)
        {
          id: user_school.school_id,
          name: user_school.school.name,
          province_id: user_school.school.province_id,
          location_id: user_school.school.location_id,
          school_type: user_school.school.school_type,
          mapping_id: user_school.id,
          mapped_at: user_school.created_at,
          updated_at: user_school.updated_at
        }
      end

      def clear_user_cache
        begin
          redis.del("user_#{@current_user.id}_profile")
          Rails.logger.info "🗑️ Cleared cache for user #{@current_user.id}"
        rescue => e
          Rails.logger.warn "⚠️ Failed to clear cache: #{e.message}"
        end
      end

      def redis
        @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
      end
    end
  end
end