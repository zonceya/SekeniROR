# Disable checksums for R2 compatibility
Rails.application.config.after_initialize do
  ActiveStorage::Blob.class_eval do
    # Override the checksum method to return nil
    def checksum
      nil
    end
  end
  
  # Disable S3 checksum validation
  if Rails.application.config.active_storage.service == :cloudflare_r2
    ActiveStorage::Service::S3Service.class_eval do
      def upload(key, io, checksum: nil, **options)
        # Remove checksum from options
        super(key, io, **options.except(:checksum))
      end
    end
  end
end