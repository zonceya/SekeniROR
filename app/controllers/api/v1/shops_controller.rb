# app/controllers/api/v1/schools_controller.rb
module Api
  module V1
    class SchoolsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token

      def index
        # Clean parameters
        province_id = params[:province_id].to_s.strip
        query = params[:query].to_s.strip.gsub(/[\n\r]/, '')

        # Validate province_id
        unless province_id.present?
          return render json: {
            schools: [],
            message: "Please select a province first"
          }
        end

        # Validate query length
        if query.present? && query.length < 2
          province = find_province(province_id)
          return render json: {
            schools: [],
            message: "Type at least 2 characters to search",
            province: province
          }
        end

        # Base query
        schools = School.where(province_id: province_id)
        
        # Apply search if query is valid
        if query.present? && query.length >= 2
          schools = schools.where('name ILIKE ?', "%#{query}%")
        end

        province = find_province(province_id)

        # Build schools data
        schools_data = schools.limit(50).map do |school|
          {
            id: school.id,
            name: school.name,
            province_id: school.province_id,
            province: province,
            town_id: school.town_id,
            school_type: school.school_type
          }
        end

        render json: {
          schools: schools_data,
          total_count: schools.count,
          province: province,
          query: query
        }
      end

      def show
        school = School.find(params[:id])
        province = find_province(school.province_id)
        
        render json: {
          school: {
            id: school.id,
            name: school.name,
            province_id: school.province_id,
            province: province,
            town_id: school.town_id,
            school_type: school.school_type
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "School not found" }, status: :not_found
      end

      private

      def find_province(province_id)
        province = Province.find_by(id: province_id)
        province ? { id: province.id, name: province.name } : nil
      end
    end
  end
end