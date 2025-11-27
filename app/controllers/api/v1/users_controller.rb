require 'redis'

class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sign_in, :update_mobile, :disable,:reactivate,:update_firebase_token ]
  before_action :authenticate_user, except: [:sign_in, :reactivate]
   # has_many :buyer_chat_rooms, class_name: 'ChatRoom', foreign_key: 'buyer_id'
  # has_many :seller_chat_rooms, class_name: 'ChatRoom', foreign_key: 'seller_id'

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
  
   def chat_rooms
    ChatRoom.where('buyer_id = ? OR seller_id = ?', id, id)
  end

  def profile
    cached_profile = redis.get("user_#{@current_user.id}_profile")

    if cached_profile
      render json: { user: @current_user, profile: JSON.parse(cached_profile) }, status: :ok
    else
      render json: { user: @current_user, profile: @current_user.profile }, status: :ok
    end
  end
  def user_ratings
    user = User.find(params[:user_id])
    ratings = Rating.where(rated_id: user.id, rating_type: 'seller_to_buyer')
                  .includes(:rater, :shop)
                  .order(created_at: :desc)
    
    user_rating = UserRating.find_or_create_by(user_id: user.id)

    render json: {
      user_rating: {
        average_rating: user_rating.average_rating,
        total_ratings: user_rating.total_ratings
      },
      ratings: ratings.map { |r| serialize_user_rating(r) }
    }, status: :ok
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
 def update_firebase_token
  unless params[:token].present?
    return render json: { error: "Firebase token is required" }, status: :unprocessable_entity
  end

  if @current_user.update(firebase_token: params[:token])
    render json: { 
      message: 'Firebase token updated successfully',
      firebase_token: @current_user.firebase_token
    }
  else
    render json: { 
      error: 'Failed to update firebase token',
      details: @current_user.errors.full_messages 
    }, status: :unprocessable_entity
  end
end
  private
  def redis
    @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
  end
  def create_profile_for(user)
    user.create_profile(image: params[:profileUrl] || "default.png") unless user.profile
  end

  def create_shop_for(user)
  return if user.shop
  
  shop = user.build_shop(
    name: "#{user.name}'s Shop",
    description: "Shop for #{user.name}"
  )
  
  unless shop.save
    Rails.logger.error "Failed to create shop: #{shop.errors.full_messages}"
    # Don't raise error here to avoid breaking user creation
  end
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
    def serialize_user_rating(rating)
    {
      id: rating.id,
      rating: rating.rating,
      review: rating.review,
      created_at: rating.created_at,
      rater: {
        id: rating.rater.id,
        name: rating.rater.name,
        avatar: rating.rater.avatar_url
      },
      shop: {
        id: rating.shop.id,
        name: rating.shop.name
      }
    }
  end
end