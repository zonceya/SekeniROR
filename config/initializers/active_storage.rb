Rails.application.config.active_storage.queues.analysis = :active_storage_analysis
Rails.application.config.active_storage.queues.purge = :active_storage_purge

# Configure Active Storage to use UUIDs
Rails.application.config.active_storage.primary_key_type = :uuid
Rails.application.config.active_storage.content_types_to_serve_as_binary -= ['image/svg+xml']