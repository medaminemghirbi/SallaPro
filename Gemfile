source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.4", ">= 7.0.4.3"

# Use sqlite3 as the database for Active Record
gem "pg", "~> 1.4.3"
gem 'jwt'

gem 'dotenv-rails', groups: [:development, :test]
gem 'active_model_serializers'
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 5.0"
gem 'byebug', '~> 11.1', '>= 11.1.3'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem 'geocoder'
gem 'activerecord-import', '~> 1.8', '>= 1.8.1'
gem 'prawn', '~> 2.5'
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors"
gem 'pycall'
gem 'faker', '~> 3.3', '>= 3.3.1'
gem 'mini_magick'
gem 'twilio-ruby'
gem 'sidekiq', '~> 6.4.0'
gem 'sidekiq-scheduler'
group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end
group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

gem 'ice_cube', '~> 0.17.0'

gem "dockerfile-rails", ">= 1.6", :group => :development
gem 'standard', require: false
gem "redis", "~> 5.3"
gem 'redis-rails'
gem "aws-sdk-s3", "~> 1.167", :require => false
gem 'kaminari'
gem 'pry', '~> 0.15.0'

gem 'receipts'
gem 'devise'
