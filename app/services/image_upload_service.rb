# app/services/image_upload_service.rb
require 'aws-sdk-s3'
require 'down'
require 'digest'

class ImageUploadService
  class ImageUploadError < StandardError; end

  # Cache duration in seconds (24 hours)
  CACHE_DURATION = 24.hours.to_i
  # Cache key prefix
  CACHE_PREFIX = 'image_upload'

  # Generic method for uploading images to any model
  def self.upload_for_record(record:, image_source:, attachment_name: :images, purpose: nil)
    begin
      Rails.logger.info "🔄 Uploading image for #{record.class.name} #{record.id} to attachment #{attachment_name}"

      # 1. Download or read the file
      file, is_downloaded = prepare_file(image_source)

      # 2. Generate the unique fingerprint (checksum)
      file_checksum = Digest::SHA256.file(file.path).hexdigest
      Rails.logger.info "📊 File checksum: #{file_checksum}"

      # 3. Create storage key based on model, purpose, and checksum
      file_extension = File.extname(file.original_filename) || '.jpg'
      
      # Determine folder structure
      folder = case record.class.name
               when 'User' then 'users/profile_pictures'
               when 'Item' then purpose || 'items/images'
               else "#{record.class.name.downcase.pluralize}/#{purpose || 'images'}"
               end
      
      r2_object_key = "#{folder}/#{file_checksum}#{file_extension}"

      # 4. Check cache first for blob existence
      cache_key = "#{CACHE_PREFIX}/blob_exists/#{r2_object_key}"
      cached_blob_exists = Rails.cache.read(cache_key)

      if cached_blob_exists
        Rails.logger.info "📦 Found blob existence in cache for key: #{r2_object_key}"
        file_exists = cached_blob_exists
      else
        # Check if this file already exists in R2
        s3_client = get_s3_client

        begin
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
            'uploaded_for_id' => record.id.to_s,
            'uploaded_for_type' => record.class.name,
            'checksum' => file_checksum,
            'purpose' => purpose.to_s
          }
        )
        Rails.logger.info "✅ New file uploaded successfully."

        # Invalidate cache since we added a new file
        Rails.cache.delete(cache_key)
      end

      # 6. Create or find the ActiveStorage Blob
      blob = find_or_create_blob(r2_object_key, file, file_checksum, record)

      return { success: false, error: "Failed to create blob" } unless blob

      # 7. Attach the blob to the record
      if record.send(attachment_name).respond_to?(:attach)
        # For single attachment (has_one_attached)
        record.send(attachment_name).attach(blob)
      else
        # For multiple attachments (has_many_attached)
        record.send(attachment_name).attach(blob) unless record.send(attachment_name).include?(blob)
      end

      # 8. Check if attachment was successful
      attached = if record.send(attachment_name).respond_to?(:attached?)
                   record.send(attachment_name).attached?
                 else
                   record.send(attachment_name).include?(blob)
                 end

      if attached
        Rails.logger.info "✅ Successfully attached image to #{record.class.name} #{record.id}."
        
        # Cache the record's image relationship
        cache_record_image_key(record, blob.key, attachment_name)
        
        return { 
          success: true, 
          duplicate: file_exists, 
          blob_key: r2_object_key, 
          checksum: file_checksum,
          blob_id: blob.id
        }
      else
        Rails.logger.error "❌ Failed to attach image"
        return { success: false, error: "Failed to attach image" }
      end

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

  # Method specifically for uploading multiple item images
 def self.upload_item_images(item, image_sources, purposes: nil)
  results = []
  
  Rails.logger.info "📤 Starting upload of #{Array(image_sources).count} images for item #{item.id}"
  
  Array(image_sources).each_with_index do |image_source, index|
    purpose = purposes ? purposes[index] : "image_#{index + 1}"
    
    Rails.logger.info "Processing image #{index + 1}: #{image_source.respond_to?(:original_filename) ? image_source.original_filename : 'URL'}"
    
    result = upload_for_record(
      record: item,
      image_source: image_source,
      attachment_name: :images,
      purpose: purpose
    )
    
    results << result
  end
  
  Rails.logger.info "✅ Completed upload: #{results.count { |r| r[:success] }} successful, #{results.count { |r| !r[:success] }} failed"
  results
end

  # Keep the original user method for backward compatibility
  def self.upload_user_profile(user, image_source)
    upload_for_record(
      record: user,
      image_source: image_source,
      attachment_name: :profile_picture,
      purpose: 'profile_picture'
    )
  end

  # Helper method to find or create blob with caching
  def self.find_or_create_blob(key, file, checksum, record = nil)
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
      # Create a new blob record
      filename = if record
                   "#{record.class.name.downcase}_#{record.id}_#{Time.now.to_i}#{File.extname(file.original_filename) || '.jpg'}"
                 else
                   file.original_filename
                 end

      # Prepare metadata
      metadata = {
        'checksum' => checksum,
        'uploaded_at' => Time.current.iso8601
      }
      
      if record
        metadata['uploaded_for_id'] = record.id.to_s
        metadata['uploaded_for_type'] = record.class.name
      end

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

  # Cache record's image key
  def self.cache_record_image_key(record, key, attachment_name)
    cache_key = "#{CACHE_PREFIX}/#{record.class.name.downcase}_#{attachment_name}/#{record.id}"
    
    cached_data = Rails.cache.read(cache_key) || { blob_keys: [] }
    cached_data[:blob_keys] << key unless cached_data[:blob_keys].include?(key)
    cached_data[:updated_at] = Time.current.iso8601
    
    Rails.cache.write(cache_key, cached_data, expires_in: CACHE_DURATION)
  end

  # Get cached image keys for a record
  def self.get_cached_image_keys(record, attachment_name)
    cache_key = "#{CACHE_PREFIX}/#{record.class.name.downcase}_#{attachment_name}/#{record.id}"
    cached = Rails.cache.read(cache_key)
    cached[:blob_keys] if cached
  end

  # Clear cache for a specific blob
  def self.clear_blob_cache(key)
    Rails.cache.delete("#{CACHE_PREFIX}/blob_exists/#{key}")
    Rails.cache.delete("#{CACHE_PREFIX}/blob/#{key}")
  end

  # Clear cache for a record's images
  def self.clear_record_image_cache(record, attachment_name)
    Rails.cache.delete("#{CACHE_PREFIX}/#{record.class.name.downcase}_#{attachment_name}/#{record.id}")
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

  private

  def self.prepare_file(image_source)
    if image_source.respond_to?(:path) && image_source.respond_to?(:original_filename)
      # Already a file upload object
      return image_source, false
    elsif image_source.respond_to?(:path)
      # Tempfile from download
      class << image_source
        attr_accessor :original_filename
      end
      image_source.original_filename ||= 'image.jpg'
      image_source.content_type ||= 'image/jpeg'
      return image_source, false
    else
      # URL - need to download
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