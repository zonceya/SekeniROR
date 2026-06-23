# app/services/image_upload_service.rb
require 'aws-sdk-s3'
require 'digest'

class ImageUploadService
  class ImageUploadError < StandardError; end

  # Upload multiple images for an Item
  def self.upload_item_images(item, image_sources)
    results = []

    Array(image_sources).each_with_index do |source, index|
      result = upload_single_image(item, source, index)
      results << result
    end

    Rails.logger.info "Image upload completed: #{results.count { |r| r[:success] }} successful, #{results.count { |r| !r[:success] }} failed"
    results
  end

  private

  def self.upload_single_image(item, image_source, index)
    Rails.logger.info "Uploading image #{index + 1} for item #{item.id}"

    begin
      # 1. Prepare file (handles both uploaded files and URLs)
      file = prepare_file(image_source)

      # 2. Generate MD5 checksum (This is what ActiveStorage expects)
      file.rewind
      checksum = Digest::MD5.base64digest(file.read)
      file.rewind

      # 3. Generate unique key
      extension = File.extname(file.original_filename || 'jpg').downcase
      key = "items/images/#{item.id}/#{SecureRandom.hex(12)}#{extension}"

      # 4. Upload to R2
      s3_client = get_s3_client
      s3_client.put_object(
        bucket: ENV['R2_BUCKET_NAME'],
        key: key,
        body: file,
        content_type: file.content_type || 'image/jpeg'
      )

      Rails.logger.info "✅ Uploaded to R2: #{key}"

      # 5. Create ActiveStorage Blob
      blob = ActiveStorage::Blob.create!(
        key: key,
        filename: file.original_filename || "image_#{index + 1}.jpg",
        content_type: file.content_type || 'image/jpeg',
        byte_size: file.size,
        checksum: checksum,
        service_name: 'r2'
      )

      # 6. Attach to item
      item.images.attach(blob)

      Rails.logger.info "✅ Successfully attached image to item #{item.id}"

      { success: true, url: blob.url, key: key, blob_id: blob.id }

    rescue => e
      Rails.logger.error "❌ Image upload failed: #{e.message}"
      { success: false, error: e.message }
    ensure
      file.close! if file.respond_to?(:close!) && file.is_a?(Tempfile)
    end
  end

  # Prepare file from various sources
  def self.prepare_file(source)
    if source.respond_to?(:read) # Uploaded file (ActionDispatch::Http::UploadedFile)
      source
    elsif source.is_a?(String) && source.start_with?('http')
      # Download from URL (common in your Android flow)
      download_from_url(source)
    else
      raise ImageUploadError, "Unsupported image source type: #{source.class}"
    end
  end

  def self.download_from_url(url)
    require 'net/http'
    require 'uri'
    require 'tempfile'

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    raise ImageUploadError, "Failed to download image: HTTP #{response.code}" unless response.code == '200'

    tempfile = Tempfile.new(['upload', '.jpg'], binmode: true)
    tempfile.write(response.body)
    tempfile.rewind

    # Add necessary methods to mimic uploaded file
    class << tempfile
      attr_accessor :original_filename, :content_type
    end

    tempfile.original_filename = File.basename(uri.path) || 'image.jpg'
    tempfile.content_type = response['content-type'] || 'image/jpeg'

    tempfile
  end

  def self.get_s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['R2_ACCESS_KEY_ID'],
      secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
      endpoint: ENV['R2_ENDPOINT'],
      region: 'auto',
      force_path_style: true
    )
  end
end