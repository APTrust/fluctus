source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.8'

# Use SCSS for stylesheets
gem 'sass-rails', '4.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem 'kaminari'
gem 'minitest'

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

#gem 'hydra-head', github: 'projecthydra/hydra-head', ref: '2be4b2a0a3a0b7cf68e38bfecc7cd7f318ceee3e'
gem 'hydra-head', '8.0.0.beta1'
gem 'active-fedora', '8.0.0.rc2'
gem 'hydra-editor', '~> 0.2.2'

gem 'devise', '3.5.6'
gem 'figaro'
# as an authorization replacement for CanCan
gem "pundit"

#gem 'omniauth-google-oauth2'
gem 'simple_form', '~> 3.2.0'
gem "hydra-role-management", "~> 0.1.0"
gem 'phony_rails'
gem 'inherited_resources'
gem 'uuidtools'

# S3 connector
#gem 'aws-s3', github: 'bartoszkopinski/aws-s3'
gem 'aws-sdk-core'

group :development do
  gem 'meta_request'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :development, :test, :demo do
  gem "jettywrapper"
  gem 'sqlite3', '1.3.10'
end

group :development, :test, :demo, :production do
  gem 'factory_girl_rails'
  gem 'faker', github: 'stympy/faker'
  gem 'quiet_assets'
  gem 'rspec-rails', '~> 3.0.0'
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
end

group :test do
  gem 'capybara', '2.3.0'
  gem 'shoulda-matchers'
  gem 'coveralls', require: false
end

group :production do
  gem 'pg' #Necessary for heroku
  gem "rails_12factor" # Necessary for heroku
end
