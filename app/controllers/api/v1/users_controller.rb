require 'redis'

class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sign_in, :reactivate, 
  :update_mobile,:send_login_otp, :verify_login_otp, :reactivate]
  before_action :authenticate_user, except: [:sign_in, :reactivate, :send_login_otp, :verify_login_otp]

# app/controllers/api/v1/users_controller.rb
def sign_in
  user = User.find_or_initialize_by(email: params[:email])
  is_new_user = user.new_record?

  if !is_new_user && user.deleted?
    return render json: { error: "Account is deactivated." }, status: :forbidden
  end

  if is_new_user
    user.assign_attributes(
      name: params[:name],
      auth_mode: params[:auth_mode] || "email",
      status: true,
      deleted: false,
      role: 'user'
    )
    
    unless user.save
      return render json: { error: "Unable to create user" }, status: :unprocessable_entity
    end
    
    # Try to upload, but don't fail if it doesn't work
    if params[:profile_picture_url].present?
      begin
        ImageUploadService.upload_user_profile(user, params[:profile_picture_url])
      rescue => e
        Rails.logger.error "Profile upload failed (continuing anyway): #{e.message}"
      end
    end
  end

  session = create_session_for(user)

  # ✅ FIX: Return original Google URL if upload failed
  profile_url = if user.profile_picture.attached?
                  generate_profile_url(user)
                elsif params[:profile_picture_url].present?
                  params[:profile_picture_url]  # Return original Google URL
                else
                  nil
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
      profile_picture_url: profile_url,  # ✅ Now has URL!
      auth_mode: user.auth_mode,
      role: user.role,
      created_at: user.created_at,
      updated_at: user.updated_at,
      school_mapped: user.school_mapped?,
      school_id: user.school_id,
      school_name: user.school_name
    },
    token: session.token,
    timestamp: Time.now.iso8601
  }, status: :ok
end
def send_login_otp
    begin
      raise "Email is required" if params[:email].blank?
      raise "Invalid email format" unless params[:email].match?(URI::MailTo::EMAIL_REGEXP)
      
      email = params[:email].downcase.strip
      user = User.find_or_initialize_by(email: email)
      
      # Check if account is deactivated
      if user.persisted? && user.deleted?
        return render json: { error: "Account is deactivated. Please contact support." }, status: :forbidden
      end
      
      # Generate OTP
      otp_code = user.generate_otp('login')
      
      # Send email with OTP
      OtpMailer.send_login_otp(email, otp_code).deliver_later
      
      Rails.logger.info "OTP sent to #{email}: #{otp_code}" if Rails.env.development?
      
      render json: {
        success: true,
        message: "Verification code sent to #{mask_email(email)}",
        data: {
          otp_token: user.otp_token,
          email: email,
          # Only include OTP in development for testing
          otp_code: (Rails.env.development? ? otp_code : nil)
        }
      }, status: :ok
      
    rescue => e
      render json: { error: "Failed to send OTP: #{e.message}" }, status: :unprocessable_entity
    end
      def verify_login_otp
    begin
      raise "OTP token is required" if params[:otp_token].blank?
      raise "OTP code is required" if params[:otp_code].blank?
      raise "Email is required" if params[:email].blank?
      
      email = params[:email].downcase.strip
      
      # Find user by email and OTP token
      user = User.find_by(email: email, otp_token: params[:otp_token])
      
      if user.nil?
        return render json: { error: "Invalid or expired session" }, status: :unprocessable_entity
      end
      
      # Verify OTP
      unless user.valid_otp?(params[:otp_code], 'login')
        return render json: { error: "Invalid or expired verification code" }, status: :unprocessable_entity
      end
      
      # Check if account is deactivated
      if user.deleted?
        return render json: { error: "Account is deactivated" }, status: :forbidden
      end
      
      # If new user, complete setup
      if user.new_record? || user.profile.nil?
        user.setup_new_user(params[:name], 'email_otp')
      end
      
      # Clear OTP data
      user.clear_otp
      
      # Create session
      session = create_session_for(user)
      
      # Handle profile picture if provided
      profile_url = nil
      if params[:profile_picture_url].present? && !user.profile_picture.attached?
        begin
          ImageUploadService.upload_user_profile(user, params[:profile_picture_url])
          profile_url = generate_profile_url(user)
        rescue => e
          Rails.logger.error "Profile upload failed: #{e.message}"
        end
      else
        profile_url = generate_profile_url(user)
      end
      
      render json: {
        success: true,
        message: user.persisted? ? "Welcome back!" : "Account created successfully!",
        auth_method: "email_otp",
        is_new_user: user.created_at > 1.minute.ago,
        user: user_serializer(user, profile_url),
        token: session.token,
        timestamp: Time.now.iso8601
      }, status: :ok
      
    rescue => e
      render json: { error: "Verification failed: #{e.message}" }, status: :bad_request
    end
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

    Rails.logger.info "📱 Updating mobile for user #{@current_user.id}"
    
    # Start transaction to update both user and profile
    User.transaction do
      if @current_user.update(mobile: params[:mobile])
        # Also update the profile's mobile
        if @current_user.profile.update(mobile: params[:mobile])
          Rails.logger.info "✅ Mobile updated successfully for user #{@current_user.id}"
          
          # Update Redis cache with updated profile
          Rails.logger.info "📦 Caching updated profile in Redis..."
          redis.setex("user_#{@current_user.id}_profile", 1.hour, @current_user.profile.reload.to_json)
          
          # Verify cache
          cached = redis.get("user_#{@current_user.id}_profile")
          
          render json: {
            message: "Mobile number updated successfully",
            user: user_serializer(@current_user),
            profile: @current_user.profile.as_json(except: [:created_at, :updated_at]),
            cache_updated: cached.present?
          }, status: :ok
        else
          Rails.logger.error "❌ Failed to update profile mobile"
          raise ActiveRecord::Rollback
        end
      else
        render json: {
          message: "Failed to update user mobile number",
          errors: @current_user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue => e
    render json: {
      message: "Failed to update mobile number",
      error: e.message
    }, status: :unprocessable_entity
  end

  def disable
    Rails.logger.debug "Disabling user with ID #{@current_user.id}"
    if @current_user.soft_delete
      render json: { message: "User has been disabled." }, status: :ok
    else
      render json: { error: "Unable to disable user." }, status: :unprocessable_entity
    end
  end
  def show
    user = User.find_by(id: params[:id])
    if user
      render json: {
        success: true,
        user: {
          id: user.id,
          name: user.name,
          mobile: user.mobile,
          school_name: user.school&.name
        }
      }
    else
      render json: { error: "User not found" }, status: :not_found
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

  def mask_email(email)
    local_part, domain = email.split('@')
    if local_part.length <= 4
      masked_local = local_part[0..1] + '***'
    else
      masked_local = local_part[0..2] + '***' + local_part[-2..-1]
    end
    "#{masked_local}@#{domain}"
  end

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

  def user_serializer(user, profile_url = nil)
  {
    id: user.id,
    name: user.name,
    email: user.email,
    mobile: user.mobile,
    username: user.username,
    profile_picture_url: profile_url || generate_profile_url(user),
    auth_mode: user.auth_mode,
    role: user.role,
    created_at: user.created_at,
    updated_at: user.updated_at,
    school_mapped: user.school_mapped?,
    school_id: user.school_id,
    school_name: user.school_name
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