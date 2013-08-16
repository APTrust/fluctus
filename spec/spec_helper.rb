# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/rspec'
require 'coveralls'
require 'simplecov'

# push test code to remote and produce locally.
Coveralls.wear!
SimpleCov.start 'rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

# Enable fake google sign_ins
OmniAuth.config.test_mode = true

# this hash is pulled directly from https://github.com/zquestz/omniauth-google-oauth2/wiki
omniauth_hash ={
    :provider => "google_oauth2",
    :uid => "123456789",
    :info => {
        :name => "John Doe",
        :email => "john@company_name.com",
        :first_name => "John",
        :last_name => "Doe",
        :image => "https://lh3.googleusercontent.com/url/photo.jpg"
    },
    :credentials => {
        :token => "token",
        :refresh_token => "another_token",
        :expires_at => 1354920555,
        :expires => true
    },
    :extra => {
        :raw_info => {
            :id => "123456789",
            :email => "user@domain.example.com",
            :verified_email => true,
            :name => "John Doe",
            :given_name => "John",
            :family_name => "Doe",
            :link => "https://plus.google.com/123456789",
            :picture => "https://lh3.googleusercontent.com/url/photo.jpg",
            :gender => "male",
            :birthday => "0000-06-25",
            :locale => "en",
            :hd => "company_name.com"
        }
    }
}

OmniAuth.config.add_mock(:google, omniauth_hash)

# Enable capybara to login and logout users
include Warden::Test::Helpers
Warden.test_mode!

# Capybara.default_driver = :selenium

RSpec.configure do |config|

  # Add all fluctus roles before testing.
  config.before(:all) do 
    ['admin', 'institutional_admin', 'institutional_user'].each do |role|
      Role.create!(name: role)
    end

    # Create our two default institutions
    FactoryGirl.create(:aptrust)
    # FactoryGirl.create(:fake_university)
  end

  config.after(:all) do 
    DescriptionObject.destroy_all
    Role.destroy_all
    User.destroy_all
    Institution.destroy_all
  end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "default"

  # config.backtrace_exclusion_patterns = Array.new
end
