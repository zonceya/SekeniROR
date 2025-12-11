# app/controllers/concerns/profile_picture_helper.rb (or within your controller)
def cached_profile_picture_url(user, expires_in: 3600)
  return nil unless user.profile_picture.attached?

  blob_key = user.profile_picture.key
  cache_key = "user:#{user.id}:profile_pic_url:#{blob_key}"

  # Fetch from cache, or generate and store if not present
  Rails.cache.fetch(cache_key, expires_in: expires_in - 300) do # Cache 5 min less than URL expiry
    generate_r2_presigned_url(blob_key, expires_in)
  end
end

private

def cached_profile_picture_url(user, expires_in: 3600)
  return nil unless user.profile_picture.attached?

  blob_key = user.profile_picture.key
  cache_key = "user:#{user.id}:profile_pic_url:#{blob_key}"

  # Fetch from cache, or generate and store if not present
  Rails.cache.fetch(cache_key, expires_in: expires_in - 300) do # Cache 5 min less than URL expiry
    generate_r2_presigned_url(blob_key, expires_in)
  end
end

def generate_r2_presigned_url(blob_key, expires_in)
  s3_client = Aws::S3::Client.new(
    access_key_id: ENV['R2_ACCESS_KEY_ID'],
    secret_access_key: ENV['R2_SECRET_ACCESS_KEY'],
    endpoint: ENV['R2_ENDPOINT'],
    region: 'auto',
    force_path_style: true
  )
  signer = Aws::S3::Presigner.new(client: s3_client)
  signer.presigned_url(:get_object,
                       bucket: ENV['R2_BUCKET_NAME'],
                       key: blob_key,
                       expires_in: expires_in)
rescue => e
  Rails.logger.error "Failed to generate presigned URL: #{e.message}"
  nil
end

# Update generate_profile_url to use caching
def generate_profile_url(user)
  cached_profile_picture_url(user)
end