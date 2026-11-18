require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ============================================================================
  # STAGING — production-parity environment
  # Same behavior as production, different secrets/hosts/logs.
  # ============================================================================

  # === CORE ===
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # === STATIC ASSETS ===
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    "cache-control" => "public, max-age=#{1.year.to_i}"
  }

  # === ACTIVE STORAGE ===
  # R2 — permanent public URLs (R2_PUBLIC_BASE_URL must be set)
  config.active_storage.service = :r2
  config.active_storage.queues.analysis = :active_storage_analysis
  config.active_storage.queues.purge    = :active_storage_purge

  # === SSL / PROXY ===
  # Cloudflare / nginx terminates TLS in front of Rails.
  # force_ssl=false is safe ONLY when a proxy handles HTTP→HTTPS redirect.
  # Verify with: curl -I http://api-staging.skoolswap.co.za/up
  config.assume_ssl = true
  config.force_ssl = false

  # === LOGGING ===
  # info, not debug — debug fills disk with SQL query spam in production-like envs
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # === JOBS / CACHE ===
  # Solid Queue + Solid Cache (matches production once you enable them)
  # If you're not running Solid yet, keep these commented.
  # config.cache_store = :solid_cache_store
  # config.active_job.queue_adapter = :solid_queue
  # config.solid_queue.connects_to = { database: { writing: :queue } }

  # === ACTION MAILER ===
  # Set real host for staging links — not example.com
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = {
    host: ENV.fetch("STAGING_HOST", "api-staging.skoolswap.co.za"),
    protocol: "https"
  }

  # === ACTION CABLE ===
  config.action_cable.mount_path = nil
  config.action_cable.url = nil

  # === I18N ===
  config.i18n.fallbacks = true

  # === ACTIVE RECORD ===
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # === HOST AUTHORIZATION (Rails 7.1+) ===
  # Reject requests to unknown hostnames — prevents host-header attacks.
  config.hosts << ENV.fetch("STAGING_HOST", "api-staging.skoolswap.co.za")
  # Allow localhost for direct curl tests on the Ubuntu box:
  config.hosts << "localhost"
  config.hosts << "127.0.0.1"

  # === DEV-ONLY BLOCK REMOVED ===
  # The OpenSSL::SSL::VERIFY_PEER override only belongs in development.rb.
  # Staging should verify peer certificates like production.
end