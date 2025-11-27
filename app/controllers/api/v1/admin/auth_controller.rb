# app/controllers/api/v1/admin/auth_controller.rb
require 'jwt'
module Api::V1::Admin
    class AuthController < BaseController
      protect_from_forgery with: :null_session
      skip_before_action :authenticate_admin!, only: [:login, :signup, :forgot_password]
      self.skip_authentication_actions = [:login, :signup, :forgot_password]
      # POST /api/v1/admin/auth/signup
     # POST /api/v1/admin/auth/signup
def signup
    admin = User.new(signup_params.merge(role: 'admin'))
    
    begin
      if admin.save
        token = generate_jwt_token(admin)
        render json: { success: true, token: token, admin: admin_response(admin) }
      else
        # Check for PG::UniqueViolation in errors
        if admin.errors.details[:email].any? { |e| e[:error] == :taken }
          render json: { 
            success: false, 
            errors: { email: ['has already been taken'] } 
          }, status: :unprocessable_entity
        else
          render json: { 
            success: false, 
            errors: admin.errors.messages 
          }, status: :unprocessable_entity
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      # Direct database constraint violation
      if e.message.include?('users_email_key') || e.message.include?('unique_email')
        render json: { 
          success: false, 
          errors: { email: ['has already been taken'] } 
        }, status: :unprocessable_entity
      else
        raise # Re-raise other uniqueness violations
      end
    end
  end
  
      # POST /api/v1/admin/auth/login
      def login
        admin = User.admins.find_by(email: params[:email])
        
        if admin&.authenticate(params[:password])
          if admin.deleted
            render json: { success: false, message: 'Account deactivated' }, status: :unauthorized
          else
            token = generate_jwt_token(admin)
            store_token_in_redis(admin, token)
            render json: { success: true, token: token, admin: admin_response(admin) }
          end
        else
          render json: { success: false, message: 'Invalid email or password' }, status: :unauthorized
        end
      end
  
      # POST /api/v1/admin/auth/forgot_password
      def forgot_password
        admin = User.admins.find_by(email: params[:email])
        if admin && !admin.deleted
          reset_token = admin.generate_password_reset_token
          render json: { 
            success: true, 
            message: 'Password reset instructions sent',
            reset_token: Rails.env.development? ? reset_token : nil
          }
        else
          render json: { success: false, message: 'Email not found or account deactivated' }, status: :not_found
        end
      end
  
      # POST /api/v1/admin/auth/logout    
      def logout
        token = request.headers['Authorization']&.split(' ')&.last
        
        if token && current_admin
          # Add token to blacklist with 24-hour expiration
          redis.setex("token_blacklist:#{token}", 86400, 1)
          
          render json: { 
            success: true, 
            message: 'Logged out successfully' 
          }
        else
          render json: { 
            success: false, 
            message: 'Invalid token' 
          }, status: :unauthorized
        end
      end
  
  
      private
  
      def signup_params
        params.require(:admin).permit(:name, :email, :password, :password_confirmation)
      end
  
      def generate_jwt_token(admin)
        payload = { 
          admin_id: admin.id,
          role: admin.role,
          exp: 24.hours.from_now.to_i
        }
        JWT.encode(payload, Rails.application.secret_key_base)
      end
  
      def admin_response(admin)
        admin.as_json(only: [:id, :name, :email, :created_at, :role])
      end
  
      def store_token_in_redis(admin, token)
        # Implementation of your Redis storage
      end
  
      def redis
        @redis ||= Redis.new
      end
    end
  end