# app/controllers/api/v1/users_controller.rb
require 'redis'

class Api::V1::UsersController < ApplicationController
before_action :authenticate_user, except: [:sign_in, :sign_up, :reactivate, :firebase_auth, :update_firebase_token]
skip_before_action :verify_authenticity_token, only: [:sign_in, :sign_up, :reactivate, :update_mobile, :firebase_auth, :update_firebase_token]

def firebase_auth
  begin
    # Validate required params
    if params[:id_token].blank?
      return render json: { error: "Firebase ID token is required" }, status: :bad_request
    end
    
    if params[:email].blank?
      return render json: { error: "Email is required" }, status: :bad_request
    end
    
    email = params[:email].downcase.strip
    
    # Verify Firebase token
    firebase_user = FirebaseTokenVerifier.verify(params[:id_token])
    
    unless firebase_user && firebase_user[:email].downcase == email
      return render json: { error: "Invalid Firebase token" }, status: :unauthorized
    end
    
    # Find or initialize user
    user = User.find_or_initialize_by(email: email)
    is_new_user = user.new_record?
    
    # ✅ CHECK FOR SOFT-DELETED USER - Reactivate and clear school
    if user.persisted? && user.deleted?
      Rails.logger.info "🔄 Reactivating soft-deleted user: #{user.email}"
      
      # Reactivate the user (this will clear school mappings)
      user.reactivate
      
      # Update user info
      user.update!(
        name: params[:name] || user.name,
        firebase_uid: firebase_user[:uid],
        auth_mode: "firebase_email_password",
        status: true
      )
      
      Rails.logger.info "✅ User reactivated with school mappings cleared"
      is_new_user = true # Treat as new user for onboarding
    end
    
    if is_new_user && !user.persisted?
      # New user signup
      user.assign_attributes(
        name: params[:name] || firebase_user[:name] || email.split('@').first,
        firebase_uid: firebase_user[:uid],
        auth_mode: "firebase_email_password",
        status: true,
        deleted: false,
        role: 'user'
      )
      
      unless user.save
        return render json: { 
          error: "Unable to create user: #{user.errors.full_messages.join(', ')}" 
        }, status: :unprocessable_entity
      end
      
      # Create associated records
      user.create_profile! unless user.profile
      
      unless user.shop
        user.create_shop!(
          name: "#{user.name}'s Shop", 
          description: "Shop for #{user.name}"
        )
      end
      
      # Create digital wallet
      unless user.digital_wallet
        user.create_digital_wallet!(
          wallet_number: generate_wallet_number,
          current_balance: 0.0,
          pending_balance: 0.0
        )
      end
      
      # Handle profile picture if provided
      if params[:profile_picture_url].present?
        begin
          ImageUploadService.upload_user_profile(user, params[:profile_picture_url])
        rescue => e
          Rails.logger.error "Profile upload failed (continuing anyway): #{e.message}"
        end
      end
      
    elsif is_new_user && user.persisted?
      # Reactivated user case - already handled above
      Rails.logger.info "✅ Reactivated user ready for onboarding: #{user.email}"
      
    else
      # Existing active user login
      if user.firebase_uid.blank?
        user.update(firebase_uid: firebase_user[:uid])
      end
      
      if params[:name].present? && user.name != params[:name]
        user.update(name: params[:name])
      end
    end
    
    # Create new session
    session = create_session_for(user)
    
    # Generate profile URL
    profile_url = generate_profile_url(user)
    
    # Log final status
    Rails.logger.info "📊 User #{user.id} - school_mapped: #{user.school_mapped?}, deleted: #{user.deleted?}"
    
    render json: {
      success: true,
      message: is_new_user ? "Account created successfully!" : "Welcome back!",
      is_new_user: is_new_user,
      user: user_serializer(user, profile_url),
      token: session.token,
      timestamp: Time.now.iso8601
    }, status: :ok
    
  rescue => e
    Rails.logger.error "Firebase authentication error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { 
      error: "Firebase authentication failed: #{e.message}" 
    }, status: :bad_request
  end
end



# POST /api/v1/users/firebase_token
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

  # POST /api/v1/users/sign_in (Google Sign-In)
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
      
      if params[:profile_picture_url].present?
        begin
          ImageUploadService.upload_user_profile(user, params[:profile_picture_url])
        rescue => e
          Rails.logger.error "Profile upload failed (continuing anyway): #{e.message}"
        end
      end
    end

    session = create_session_for(user)

    profile_url = if user.profile_picture.attached?
                    generate_profile_url(user)
                  elsif params[:profile_picture_url].present?
                    params[:profile_picture_url]
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
        profile_picture_url: profile_url,
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


# app/controllers/api/v1/users_controller.rb

def sign_up
  begin
    raise "Name is required" if params[:name].blank?
    raise "Email is required" if params[:email].blank?
    raise "Password is required" if params[:password].blank?
    raise "Password confirmation is required" if params[:password_confirmation].blank?
    raise "Passwords do not match" if params[:password] != params[:password_confirmation]
    raise "Invalid email format" unless params[:email].match?(URI::MailTo::EMAIL_REGEXP)

    email = params[:email].downcase.strip

    # Check if user already exists
    existing_user = User.find_by(email: email)
    
    if existing_user
      # If user exists, send OTP for login
           
      return render json: {
        success: true,
        message: "Account already exists. OTP sent for login.",
        data: {
          otp_token: existing_user.otp_token,
          email: email,
          purpose: "LOGIN",
          otp_code: (Rails.env.development? ? otp_code : nil)
        }
      }, status: :ok
    end

    # Create new user
    user = User.new(
      name: params[:name],
      email: email,
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      auth_mode: "email",
      status: true,
      deleted: false,
      role: 'user'
    )

    if user.save
      # Create profile, shop, and wallet
      user.create_profile! unless user.profile
      user.create_shop!(name: "#{user.name}'s Shop", description: "Shop for #{user.name}") unless user.shop
      
      # ✅ GENERATE OTP FOR SIGNUP
      otp_code = user.generate_otp('signup')
      
      # ✅ SEND OTP EMAIL
      OtpMailer.send_login_otp(email, otp_code).deliver_now
      
      # Create session
      session = user.user_sessions.create(token: SecureRandom.hex(16))
      
      render json: {
        success: true,
        message: "Account created successfully! Please verify your email.",
        data: {
          otp_token: user.otp_token,
          email: email,
          purpose: "SIGNUP",
          otp_code: (Rails.env.development? ? otp_code : nil)
        }
      }, status: :created
    else
      render json: { 
        success: false, 
        message: "Failed to create account", 
        errors: user.errors.full_messages 
      }, status: :unprocessable_entity
    end
  rescue => e
    render json: { 
      success: false, 
      message: e.message 
    }, status: :bad_request
  end
end
  
  # ==================== PROFILE METHODS ====================

  # GET /api/v1/users/profile
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

  # GET /api/v1/users/:id
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

  # GET /api/v1/users/:user_id/ratings
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

  # PUT /api/v1/users/update_mobile
  def update_mobile
    unless params[:mobile].present?
      return render json: { error: "Mobile number is required." }, status: :unprocessable_entity
    end

    Rails.logger.info "📱 Updating mobile for user #{@current_user.id}"
    
    User.transaction do
      if @current_user.update(mobile: params[:mobile])
        if @current_user.profile.update(mobile: params[:mobile])
          Rails.logger.info "✅ Mobile updated successfully for user #{@current_user.id}"
          
          redis.setex("user_#{@current_user.id}_profile", 1.hour, @current_user.profile.reload.to_json)
          
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

  # PUT /api/v1/users/update_profile_picture
  def update_profile_picture
    begin
      upload_result = nil
      
      if params[:profile_picture].present?
        upload_result = ImageUploadService.upload_user_profile(@current_user, params[:profile_picture])
      elsif params[:profile_picture_url].present?
        upload_result = ImageUploadService.upload_user_profile(@current_user, params[:profile_picture_url])
      else
        return render json: {
          error: "No profile picture provided"
        }, status: :unprocessable_entity
      end

      if upload_result[:success]
        redis.del("user_#{@current_user.id}_profile")
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

  # POST /api/v1/users/firebase_token
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

  # ==================== CHAT METHODS ====================

  # GET /api/v1/users/chat_rooms
  def chat_rooms
    user_chat_rooms = @current_user.chat_rooms
    render json: { chat_rooms: user_chat_rooms.as_json(except: [:created_at, :updated_at]) }, status: :ok
  end

  # ==================== ACCOUNT MANAGEMENT ====================

  # POST /api/v1/users/disable
  def disable
    Rails.logger.debug "Disabling user with ID #{@current_user.id}"
    if @current_user.soft_delete
      render json: { message: "User has been disabled." }, status: :ok
    else
      render json: { error: "Unable to disable user." }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/users/reactivate
  def reactivate
    user = User.find_by("email = ? OR username = ?", params[:email], params[:username])

    if user&.deleted?
      user.reactivate
      render json: { message: "Account reactivated successfully." }, status: :ok
    else
      render json: { error: "Invalid request or account not deactivated." }, status: :unprocessable_entity
    end
  end

  # ==================== PRIVATE METHODS ====================

  private


def generate_wallet_number
  loop do
    number = "SW#{Time.now.to_i}#{rand(1000..9999)}"
    break number unless DigitalWallet.exists?(wallet_number: number)
  end
end

def verify_firebase_token(id_token)
  return nil if id_token.blank?
  
  # Load from JSON file instead of ENV
  firebase_config = JSON.parse(File.read(Rails.root.join('config/firebase-service-account.json')))
  project_id = firebase_config['project_id']
  
  begin
    # Decode token without verification to get the key ID
    unverified = JWT.decode(id_token, nil, false)
    kid = unverified[1]['kid']
    
    # Fetch public keys from Firebase
    cert_url = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
    response = Faraday.get(cert_url)
    certs = JSON.parse(response.body)
    
    # Get the public key
    public_key = OpenSSL::X509::Certificate.new(certs[kid]).public_key
    
    # Verify the token
    decoded = JWT.decode(id_token, public_key, true, {
      algorithm: 'RS256',
      iss: "https://securetoken.google.com/#{project_id}",
      aud: project_id,
      verify_iss: true,
      verify_aud: true,
      verify_expiration: true
    })
    
    payload = decoded[0]
    
    {
      uid: payload['sub'],
      email: payload['email'],
      email_verified: payload['email_verified']
    }
  rescue => e
    Rails.logger.error "Firebase token verification failed: #{e.message}"
    nil
  end
end

  def mask_email(email)
    local_part, domain = email.split('@')
    if local_part.length <= 4
      masked_local = local_part[0..1] + '***'
    else
      masked_local = local_part[0..2] + '***' + local_part[-2..-1]
    end
    "#{masked_local}@#{domain}"
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
    return nil unless user.profile_picture.attached?
    
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

  def simple_upload(user, image_url)
    require 'down'
    
    begin
      Rails.logger.info "Simple upload for user #{user.id}"
      
      tempfile = Down.download(image_url)
      Rails.logger.info "Downloaded: #{tempfile.original_filename}, #{tempfile.size} bytes"
      
      user.profile_picture.attach(
        io: tempfile,
        filename: "user_#{user.id}_profile_#{Time.now.to_i}.jpg",
        content_type: 'image/jpeg'
      )
      
      if user.profile_picture.attached?
        Rails.logger.info "✅ Simple upload successful! File key: #{user.profile_picture.key}"
        sleep 1
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
end