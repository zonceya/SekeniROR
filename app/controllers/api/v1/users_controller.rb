require 'redis'

class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sign_in, :reactivate,:update_mobile]
  before_action :authenticate_user, except: [:sign_in, :reactivate]

def sign_in
  user = User.find_or_initialize_by(email: params[:email])
  is_new_user = user.new_record?

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
      return render json: { error: "Unable to create user", details: user.errors.full_messages }, status: :unprocessable_entity
    end
    
    # Upload profile picture if provided
  # Upload profile picture if provided
    if params[:profile_picture_url].present?
      upload_result = ImageUploadService.upload_user_profile(user, params[:profile_picture_url])
      unless upload_result[:success]
        Rails.logger.error "Failed to upload profile picture for new user #{user.id}: #{upload_result[:error]}"
      end
    end
  elsif params[:profile_picture_url].present? && !user.profile_picture.attached?
    # Existing user without profile picture - try to upload
    upload_result = ImageUploadService.upload_user_profile(user, params[:profile_picture_url])
    unless upload_result[:success]
      Rails.logger.warn "Failed to upload profile picture for existing user #{user.id}: #{upload_result[:error]}"
    end
  end

  session = create_session_for(user)

  # Generate profile picture URL if exists
  profile_url = nil
  if user.profile_picture.attached?
    profile_url = generate_profile_url(user)
  end

  render json: {
    success: true,
    message: "Sign in successful",
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      mobile: user.mobile,
      username: user.username,
      profile_picture_url: profile_url,
      auth_mode: user.auth_mode,
      role: user.role,
      created_at: user.created_at,
      updated_at: user.updated_at
    },
    token: session.token,
    timestamp: Time.now.iso8601
  }, status: :ok
end

  def chat_rooms
    user_chat_rooms = @current_user.chat_rooms
    render json: { chat_rooms: user_chat_rooms.as_json(except: [:created_at, :updated_at]) }, status: :ok
  end

  def profile
    cached_profile = redis.get("user_#{@current_user.id}_profile")

    if cached_profile
      render json: { 
        user: user_serializer(@current_user), 
        profile: JSON.parse(cached_profile) 
      }, status: :ok
    else
      render json: { 
        user: user_serializer(@current_user), 
        profile: @current_user.profile.as_json(except: [:created_at, :updated_at])
      }, status: :ok
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

  # Update both user and profile
  @current_user.update(mobile: params[:mobile])
  @current_user.profile.update(mobile: params[:mobile]) if @current_user.profile

  if @current_user.valid?
    # Cache the updated profile
    redis.setex("user_#{@current_user.id}_profile", 1.hour, @current_user.profile.to_json)
    
    render json: {
      message: "Mobile number updated successfully",
      user: user_serializer(@current_user),  # This should include the mobile
      profile: @current_user.profile.as_json(except: [:created_at, :updated_at]),
      cache_updated: true
    }, status: :ok
  else
    render json: {
      message: "Failed to update user mobile number",
      errors: @current_user.errors.full_messages
    }, status: :unprocessable_entity
  end
end

  # Add Redis logging
  Rails.logger.info "📱 Updating mobile for user #{@current_user.id}"
  
  if @current_user.update(mobile: params[:mobile])
    Rails.logger.info "✅ Mobile updated successfully for user #{@current_user.id}"
    Rails.logger.info "📦 Caching updated profile in Redis..."
    
    # Cache the updated profile
    redis.setex("user_#{@current_user.id}_profile", 1.hour, @current_user.profile.to_json)
    
    # Verify it was cached
    cached = redis.get("user_#{@current_user.id}_profile")
    if cached
      Rails.logger.info "✅ Redis cache updated successfully for user #{@current_user.id}"
    else
      Rails.logger.error "❌ Failed to update Redis cache for user #{@current_user.id}"
    end

    render json: {
      message: "Mobile number updated successfully",
      user: user_serializer(@current_user),
      profile: @current_user.profile.as_json(except: [:created_at, :updated_at]),
      cache_updated: cached.present?
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
  

def update_profile_picture
  begin
    upload_result = nil
    
    if params[:profile_picture].present?
      # Handle direct file upload
      upload_result = ImageUploadService.upload_user_profile(@current_user, params[:profile_picture])
    elsif params[:profile_picture_url].present?
      # Handle URL upload (from Google Sign-In)
      upload_result = ImageUploadService.upload_user_profile(@current_user, params[:profile_picture_url])
    else
      return render json: {
        error: "No profile picture provided"
      }, status: :unprocessable_entity
    end

    if upload_result[:success]
      # Clear cache
      redis.del("user_#{@current_user.id}_profile")
      
      # Generate new URL
      profile_url = @current_user.profile_picture.attached? ? generate_profile_url(@current_user) : nil
      
      render json: {
        message: "Profile picture updated successfully",
        profile_picture_url: profile_url
      }, status: :ok
    else
      render json: {
        error: "Failed to update profile picture: #{upload_result[:error]}"
      }, status: :unprocessable_entity
    end
    
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

  private
    def simple_upload(user, image_url)
    require 'down'
    
    begin
      Rails.logger.info "Simple upload for user #{user.id}"
      
      # Download file
      tempfile = Down.download(image_url)
      Rails.logger.info "Downloaded: #{tempfile.original_filename}, #{tempfile.size} bytes"
      
      # Use direct attachment without create_and_upload!
      user.profile_picture.attach(
        io: tempfile,
        filename: "user_#{user.id}_profile_#{Time.now.to_i}.jpg",
        content_type: 'image/jpeg'
      )
      
      if user.profile_picture.attached?
        Rails.logger.info "✅ Simple upload successful! File key: #{user.profile_picture.key}"
        
        # Check if file actually exists in R2
        sleep 1 # Give it a moment to upload
        exists = user.profile_picture.service.exist?(user.profile_picture.key)
        Rails.logger.info "File exists in R2: #{exists}"
        
        return true
      else
        Rails.logger.error "❌ Simple upload failed"
        return false
      end
      
      tempfile.close
    rescue => e
      Rails.logger.error "❌ Upload error: #{e.message}"
      return false
    end
  end
  def attempt_profile_picture_upload(user, image_url)
    return unless image_url.present?
    
    # Use a background job or async approach
    Thread.new do
      begin
        blob = ImageUploadService.upload_from_url(image_url, "user_#{user.id}_profile")
        user.profile_picture.attach(blob) if blob
      rescue => e
        Rails.logger.warn "Profile picture upload failed: #{e.message}"
      ensure
        ActiveRecord::Base.connection.close
      end
    end
  end
  
  def redis
    @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
  end
  
  def upload_profile_picture(user, image_url)
    blob = ImageUploadService.upload_from_url(
      image_url, 
      "user_#{user.id}_profile"
    )
    user.profile_picture.attach(blob) if blob
  end

  def user_serializer(user)
  {
    id: user.id,
    name: user.name,
    email: user.email,
    mobile: user.mobile,
    username: user.username,
    profile_picture_url: generate_profile_url(user),  # Use cached version
    auth_mode: user.auth_mode,
    role: user.role,
    created_at: user.created_at,
    updated_at: user.updated_at
  }
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
  def generate_profile_url(user)
  s3_client = Aws::S3::Client.new(
    access_key_id: ENV['R2_ACCESS_KEY_ID'],
    secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
    endpoint: ENV['R2_ENDPOINT'],
    region: 'auto',
    force_path_style: true
  )
  
  signer = Aws::S3::Presigner.new(client: s3_client)
  signer.presigned_url(
    :get_object,
    bucket: ENV['R2_BUCKET_NAME'],
    key: user.profile_picture.key,
    expires_in: 3600
  )
rescue => e
  Rails.logger.error "Failed to generate profile URL: #{e.message}"
  nil
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