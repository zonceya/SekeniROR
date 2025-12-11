require 'aws-sdk-s3'
require 'down'
require 'digest'

class ImageUploadService
  class ImageUploadError < StandardError; end

  # Cache duration in seconds (24 hours)
  CACHE_DURATION = 24.hours.to_i
  # Cache key prefix
  CACHE_PREFIX = 'image_upload'

  # Main method for uploading user profile pictures with deduplication
  def self.upload_user_profile(user, image_source)
    begin
      Rails.logger.info "🔄 Uploading profile picture for user #{user.id}"

      # 1. Download or read the file
      file, is_downloaded = prepare_file(image_source)

      # 2. Generate the unique fingerprint (checksum) of the file's content
      file_checksum = Digest::SHA256.file(file.path).hexdigest
      Rails.logger.info "📊 File checksum: #{file_checksum}"

      # 3. Create the definitive storage key using the checksum
      file_extension = File.extname(file.original_filename) || '.jpg'
      r2_object_key = "users/profile_pictures/#{file_checksum}#{file_extension}"

      # 4. Check cache first for blob existence
      cache_key = "#{CACHE_PREFIX}/blob_exists/#{r2_object_key}"

      # Check if blob exists in cache
      cached_blob_exists = Rails.cache.read(cache_key)

      if cached_blob_exists
        Rails.logger.info "📦 Found blob existence in cache for key: #{r2_object_key}"
        file_exists = cached_blob_exists
      else
        # Check if this file already exists in R2
        s3_client = get_s3_client

        begin
          # This is a fast, lightweight check (HEAD request)
          s3_client.head_object(bucket: ENV['R2_BUCKET_NAME'], key: r2_object_key)
          file_exists = true
          Rails.logger.info "✅ File already exists in R2 at key: #{r2_object_key}"
        rescue Aws::S3::Errors::NotFound
          file_exists = false
          Rails.logger.info "🆕 File not found in R2. Will upload new file."
        end

        # Cache the result
        Rails.cache.write(cache_key, file_exists, expires_in: CACHE_DURATION)
      end

      # 5. Upload only if the file does NOT exist
      unless file_exists
        Rails.logger.info "📤 Uploading new file to R2 key: #{r2_object_key}"
        s3_client ||= get_s3_client
        s3_client.put_object(
          bucket: ENV['R2_BUCKET_NAME'],
          key: r2_object_key,
          body: file,
          content_type: file.content_type || 'image/jpeg',
          metadata: {
            'uploaded_at' => Time.current.iso8601,
            'uploaded_by_user_id' => user.id.to_s,
            'checksum' => file_checksum
          }
        )
        Rails.logger.info "✅ New file uploaded successfully."

        # Invalidate cache since we added a new file
        Rails.cache.delete(cache_key)
      end

      # 6. Create or find the ActiveStorage Blob
      blob = find_or_create_blob(r2_object_key, file, file_checksum, user.id)

      return { success: false, error: "Failed to create blob" } unless blob

      # 7. Check if user already has this exact image attached
      current_attachment = user.profile_picture.attachment
      needs_update = true

      if current_attachment && current_attachment.blob_id == blob.id
        Rails.logger.info "⚠️ User already has this exact image. No change needed."
        needs_update = false
      end

      # 8. Only update if needed
      if needs_update
        user.profile_picture.purge if user.profile_picture.attached?
        user.profile_picture.attach(blob)

        if user.profile_picture.attached?
          Rails.logger.info "✅ Successfully attached new image to user #{user.id}."
        else
          Rails.logger.error "❌ Failed to attach profile picture"
          return { success: false, error: "Failed to attach profile picture" }
        end

        # Cache the user's current profile picture key
        cache_user_profile_key(user, r2_object_key)
      end

      return { success: true, duplicate: !needs_update, blob_key: r2_object_key, checksum: file_checksum }

    rescue => e
      Rails.logger.error "❌ Upload/attachment failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
      return { success: false, error: e.message }
    ensure
      # Clean up the temporary file if we downloaded it
      if file && is_downloaded
        file.close
        file.unlink
      end
    end
  end

  # Helper method to find or create blob with caching
  def self.find_or_create_blob(key, file, checksum, user_id = nil)
    cache_key = "#{CACHE_PREFIX}/blob/#{key}"

    # Try to find blob in cache first
    cached_blob = Rails.cache.read(cache_key)
    if cached_blob
      Rails.logger.info "📦 Found blob in cache for key: #{key}"
      return ActiveStorage::Blob.find_by(id: cached_blob[:id]) if cached_blob[:id]
    end

    # Try to find existing blob in database
    blob = ActiveStorage::Blob.find_by(key: key)

    unless blob
      # Create a new blob record if it's the first time we've seen this key
      filename = user_id ? "user_#{user_id}_profile#{File.extname(file.original_filename) || '.jpg'}" : file.original_filename

      # Prepare metadata
      metadata = {
        'checksum' => checksum,
        'uploaded_at' => Time.current.iso8601
      }
      metadata['uploaded_by_user_id'] = user_id.to_s if user_id

      blob = ActiveStorage::Blob.new(
        key: key,
        filename: filename,
        content_type: file.content_type || 'image/jpeg',
        byte_size: file.size,
        checksum: checksum,
        metadata: metadata,
        service_name: 'r2'
      )

      if blob.save
        Rails.logger.info "💾 Created new ActiveStorage Blob record."

        # Cache the blob info
        cache_blob_info(blob, key)
      else
        Rails.logger.error "❌ Failed to create blob: #{blob.errors.full_messages}"
        return nil
      end
    else
      Rails.logger.info "🔍 Found existing ActiveStorage Blob for this image."

      # Cache the blob info if not already cached
      cache_blob_info(blob, key) unless cached_blob
    end

    blob
  end

  # Cache blob information
  def self.cache_blob_info(blob, key)
    cache_key = "#{CACHE_PREFIX}/blob/#{key}"
    Rails.cache.write(cache_key, {
      id: blob.id,
      key: blob.key,
      filename: blob.filename,
      created_at: blob.created_at
    }, expires_in: CACHE_DURATION)
  end

  # Cache user's current profile picture key
  def self.cache_user_profile_key(user, key)
    cache_key = "#{CACHE_PREFIX}/user_profile/#{user.id}"
    Rails.cache.write(cache_key, {
      blob_key: key,
      updated_at: Time.current.iso8601
    }, expires_in: CACHE_DURATION)
  end

  # Get cached user profile key
  def self.get_cached_user_profile_key(user)
    cache_key = "#{CACHE_PREFIX}/user_profile/#{user.id}"
    cached = Rails.cache.read(cache_key)
    cached[:blob_key] if cached
  end

  # Clear cache for a specific blob
  def self.clear_blob_cache(key)
    Rails.cache.delete("#{CACHE_PREFIX}/blob_exists/#{key}")
    Rails.cache.delete("#{CACHE_PREFIX}/blob/#{key}")
  end

  # Clear cache for a user's profile
  def self.clear_user_profile_cache(user)
    Rails.cache.delete("#{CACHE_PREFIX}/user_profile/#{user.id}")
  end

  # Get S3 client (memoized)
  def self.get_s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['R2_ACCESS_KEY_ID'],
      secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
      endpoint: ENV['R2_ENDPOINT'],
      region: 'auto',
      force_path_style: true
    )
  end

  # Optional: Keep this method for general uploads if needed
  def self.upload_from_url(image_url, filename)
    return nil unless image_url.present?

    begin
      Rails.logger.info "🔄 Direct R2 upload from URL: #{image_url}"

      # Download image
      tempfile = Down.download(
        image_url,
        headers: {
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept' => 'image/*'
        }
      )

      # Generate checksum
      checksum = Digest::SHA256.file(tempfile.path).hexdigest
      file_extension = File.extname(tempfile.original_filename) || '.jpg'
      r2_key = "uploads/#{filename}_#{checksum}#{file_extension}"

      # Upload to R2
      s3_client = get_s3_client

      # Check cache first
      cache_key = "#{CACHE_PREFIX}/blob_exists/#{r2_key}"
      cached_exists = Rails.cache.read(cache_key)

      unless cached_exists
        s3_client.put_object(
          bucket: ENV['R2_BUCKET_NAME'],
          key: r2_key,
          body: tempfile,
          content_type: tempfile.content_type || 'image/jpeg',
          metadata: {
            'uploaded_at' => Time.current.iso8601,
            'checksum' => checksum
          }
        )

        # Cache the result
        Rails.cache.write(cache_key, true, expires_in: CACHE_DURATION)
      end

      # Create blob using helper
      blob = find_or_create_blob(r2_key, tempfile, checksum)

      blob ? blob : nil

    rescue => e
      Rails.logger.error "❌ Upload error: #{e.message}"
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end
  end

  private

  def self.prepare_file(image_source)
    if image_source.respond_to?(:path)
      return image_source, false
    else
      require 'net/http'
      require 'uri'

      Rails.logger.info "📥 Downloading from URL: #{image_source}"

      begin
        uri = URI.parse(image_source)
        response = Net::HTTP.get_response(uri)

        if response.code != '200'
          raise ImageUploadError, "HTTP #{response.code}"
        end

        tempfile = Tempfile.new(['image', '.jpg'], binmode: true)
        tempfile.write(response.body)
        tempfile.rewind

        class << tempfile
          attr_accessor :original_filename, :content_type
        end

        tempfile.original_filename = File.basename(uri.path) || 'image.jpg'
        tempfile.content_type = response['content-type'] || 'image/jpeg'

        Rails.logger.info "✅ Downloaded #{tempfile.size} bytes"
        return tempfile, true

      rescue => e
        Rails.logger.error "❌ Download failed: #{e.message}"
        raise ImageUploadError, "Could not download image: #{e.message}"
      end
    end
  end
end
