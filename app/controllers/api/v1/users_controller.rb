require 'redis'

class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sign_in, :update_mobile, :disable,:reactivate]
  before_action :authenticate_user, except: [:sign_in, :reactivate]
 
  def sign_in
    user = User.find_or_initialize_by(email: params[:email])
    @current_user = user unless user.new_record?
    is_new_user = user.new_record?
  
    # ⛔ Block sign-in if user is soft-deleted
    if !is_new_user && user.deleted?
      return render json: { error: "Account is deactivated. Please contact support to reactivate." }, status: :forbidden
    end
  
    if is_new_user
      user.assign_attributes(
        name: params[:name],
        auth_mode: params[:auth_mode] || params[:auth_Mode] || "email",
        status: true,
        deleted: false,
        role: 'user'
      )
      unless user.save
        Rails.logger.debug "❌ User creation failed: #{user.errors.full_messages}"
        return render json: { error: "Unable to create user", details: user.errors.full_messages }, status: :unprocessable_entity
      end
      user.reload
  
      create_profile_for(user)
      create_shop_for(user)
    end
  
    session = create_session_for(user)
  
    render json: {
      message: "Sign in successful",
      user: user,
      profile: user.profile,
      shop: user.shop,
      token: session.token
    }, status: :ok
  end
  

  def profile
    cached_profile = redis.get("user_#{@current_user.id}_profile")

    if cached_profile
      render json: { user: @current_user, profile: JSON.parse(cached_profile) }, status: :ok
    else
      render json: { user: @current_user, profile: @current_user.profile }, status: :ok
    end
  end

  def update_mobile
    unless params[:mobile].present?
      return render json: { error: "Mobile number is required." }, status: :unprocessable_entity
    end

    if @current_user.update(mobile: params[:mobile])
      redis.setex("user_#{@current_user.id}_profile", 1.hour, @current_user.profile.to_json)

      render json: {
        message: "Mobile number updated successfully",
        user: @current_user,
        profile: @current_user.profile
      }, status: :ok
    else
      render json: {
        message: "Failed to update user mobile number",
        errors: @current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def disable
    Rails.logger.debug "Disabling user with ID #{@current_user.id}"
    if @current_user.soft_delete
      render json: { message: "User has been disabled." }, status: :ok
    else
      render json: { error: "Unable to disable user." }, status: :unprocessable_entity
    end
  end

  def reactivate
    user = User.find_by("email = ? OR username = ?", params[:email], params[:username])

    if user&.deleted?
      user.reactivate
      render json: { message: "Account reactivated successfully." }, status: :ok
    else
      render json: { error: "Invalid request or account not deactivated." }, status: :unprocessable_entity
    end
  end

  private

  def create_profile_for(user)
    user.create_profile(image: params[:profileUrl] || "default.png") unless user.profile
  end

  def create_shop_for(user)
    user.create_shop(name: "#{user.name}'s Shop") unless user.shop
  end

  def create_session_for(user)
    user.user_sessions.destroy_all
    session = user.user_sessions.create(token: SecureRandom.hex(16))
    cache_user_data(user, session)
    session
  end

  def cache_user_data(user, session)
    redis.set("user_#{user.id}_profile", user.profile.to_json)
    redis.set("user_#{user.id}_session", session.token)
    Rails.logger.debug "📦 Redis cache updated"
  end

  def redis
    @redis ||= Redis.new(host: 'localhost', port: 6379)
  end

  def authenticate_user
    token = request.headers["Authorization"]&.split(" ")&.last
    session = UserSession.find_by(token: token)

    if session
      if session.user.deleted?
        render json: { error: "Account is deactivated. Please contact support to reactivate." }, status: :forbidden
      else
        @current_user = session.user
      end
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end