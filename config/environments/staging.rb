require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Reload application code when files change.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports while testing staging.
  config.consider_all_requests_local = true

  config.server_timing = true

  # Controller caching
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = {
      "cache-control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store

  # Cloudflare R2
  config.active_storage.service = :r2

  # Host authorization
config.hosts << "127.0.0.1"
config.hosts << "localhost"
config.hosts << "192.168.0.11"
config.hosts << "api.skoolswap.co.za"
  config.force_ssl = false

  # Background jobs
  config.active_job.queue_adapter = :async

  # Active Record
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true

  # Active Job logging
  config.active_job.verbose_enqueue_logs = true

  # Action View
  config.action_view.annotate_rendered_view_with_filenames = true

  # Action Controller
  config.action_controller.raise_on_missing_callback_actions = false

  # API URL generation
  config.action_controller.default_url_options = {
    host: "api.skoolswap.co.za"
  }

  # Mailer
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV["SMTP_PORT"],
    domain: ENV["SMTP_DOMAIN"],
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: "plain",
    enable_starttls_auto: true,
    open_timeout: 30,
    read_timeout: 30
  }

  config.action_mailer.default_options = {
    from: "#{ENV['DEFAULT_FROM_NAME']} <#{ENV['DEFAULT_FROM_EMAIL']}>"
  }

  config.action_mailer.default_url_options = {
    host: "api.skoolswap.co.za"
  }

  config.active_support.deprecation = :log
end