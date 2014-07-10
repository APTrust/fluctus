Fluctus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Don't reload classes on every request.
  config.cache_classes = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show limited error reports. Enable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false
  config.assets.logger = false

  # Sets up mailing host for password resets
  Rails.application.routes.default_url_options[:host] = 'localhost:3000'
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # send password reset emails to a file
  config.action_mailer.delivery_method = :file

  # log only errors, otherwise, we end up with huge log files
  # that eat up all our disk space.
  config.log_level = :error
end
