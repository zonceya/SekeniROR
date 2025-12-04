# app/services/image_upload_service.rb
require 'aws-sdk-s3'
require 'down'

class ImageUploadService
  class ImageUploadError < StandardError; end

  # Main method for uploading user profile pictures
  def self.upload_user_profile(user, image_source)
    begin
      Rails.logger.info "🔄 Uploading profile picture for user #{user.id}"
      
      # Handle both file uploads and URLs
      if image_source.respond_to?(:path) # It's a file upload
        file = image_source
        is_downloaded = false
      else # It's a URL
        file = Down.download(
          image_source,
          headers: {
            'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept' => 'image/*'
          }
        )
        is_downloaded = true
      end
      
      # Generate unique filename
      filename = "user_#{user.id}_profile_#{Time.now.to_i}"
      file_extension = File.extname(file.original_filename) || '.jpg'
      unique_filename = "#{filename}#{file_extension}"
      
      # Use our R2-compatible upload
      blob = upload_to_r2(file, unique_filename)
      
      if blob
        # Clear existing profile picture
        user.profile_picture.purge if user.profile_picture.attached?
        
        # Attach the new blob
        user.profile_picture.attach(blob)
        
        if user.profile_picture.attached?
          Rails.logger.info "✅ Profile picture updated successfully! Key: #{blob.key}"
          return true
        else
          Rails.logger.error "❌ Failed to attach profile picture"
          return false
        end
      else
        Rails.logger.error "❌ Failed to upload image to R2"
        return false
      end
      
    rescue => e
      Rails.logger.error "❌ Profile upload error: #{e.message}"
      return false
    ensure
      # Only cleanup downloaded files
      if file && is_downloaded
        file.close
        file.unlink
      end
    end
  end

  # Direct R2 upload method
  def self.upload_to_r2(file, filename)
    return nil unless file.present?

    begin
      # Initialize S3 client for R2
      s3_client = Aws::S3::Client.new(
        access_key_id: ENV['R2_ACCESS_KEY_ID'],
        secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
        endpoint: ENV['R2_ENDPOINT'],
        region: 'auto',
        force_path_style: true
      )
      
      # Generate unique key with folder structure
      file_extension = File.extname(file.original_filename) || '.jpg'
      key = "uploads/#{filename}"
      
      Rails.logger.info "📤 Uploading to R2: #{key}"
      
      # Upload directly to R2
      s3_client.put_object(
        bucket: ENV['R2_BUCKET_NAME'],
        key: key,
        body: file,
        content_type: file.content_type || 'image/jpeg'
      )
      
      Rails.logger.info "✅ Direct R2 upload successful!"
      
      # Create ActiveStorage blob record manually
      blob = ActiveStorage::Blob.new(
        key: key,
        filename: filename,
        content_type: file.content_type || 'image/jpeg',
        byte_size: file.size,
        checksum: Digest::MD5.base64digest(File.read(file.path)),
        service_name: 'r2'
      )
      
      if blob.save
        Rails.logger.info "✅ ActiveStorage blob created: #{blob.key}"
        blob
      else
        Rails.logger.error "❌ Failed to create blob: #{blob.errors.full_messages}"
        nil
      end
      
    rescue => e
      Rails.logger.error "❌ R2 upload error: #{e.message}"
      nil
    end
  end
end