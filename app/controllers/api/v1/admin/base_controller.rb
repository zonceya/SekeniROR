# app/controllers/api/v1/admin/base_controller.rb
module Api::V1::Admin
    class BaseController < ApplicationController
      # Define which actions skip authentication
      class_attribute :skip_authentication_actions
      self.skip_authentication_actions = []
      
      before_action :authenticate_admin!, unless: :skip_authentication?
      protect_from_forgery with: :null_session
  
      attr_reader :current_admin
  
      private
  
      def skip_authentication?
        self.class.skip_authentication_actions.include?(action_name.to_sym)
      end
      
  
      def authenticate_admin!
        token = request.headers['Authorization']&.split(' ')&.last
        return unauthorized_response('Missing token') unless token
  
        if token_blacklisted?(token)
          return unauthorized_response('Token revoked')
        end
  
        begin
          @current_admin = fetch_admin_from_token(token)
          unauthorized_response('Account deactivated') if @current_admin&.deleted?
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          unauthorized_response('Invalid token')
        end
      end
  
      def fetch_admin_from_token(token)
        decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
        User.admins.find(decoded['admin_id'])
      end
  
      def token_blacklisted?(token)
        redis.exists?("token_blacklist:#{token}") == 1
      end
  
      def unauthorized_response(message)
        render json: { error: message }, status: :unauthorized
      end
  
      def redis
        @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
      end
    end
  end