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

  # Should we show the "Send Object to DPN" button to users
  # whose institutions are members of DPN?
  config.show_send_to_dpn_button = true

  # send password reset emails to a file
  config.action_mailer.default_url_options = {:host => 'test.aptrust.org'}
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
  config.action_mailer.smtp_settings = {
    :address => "email-smtp.us-east-1.amazonaws.com",
    :authentication => :login,
    :enable_starttls_auto => true,
    :port    => 465,
    :user_name => ENV['AWS_SES_USER'],
    :password => ENV['AWS_SES_PASSWORD']
  }

  config.log_level = :warn
end
