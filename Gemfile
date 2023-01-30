# frozen_string_literal: true

source 'https://rubygems.org'
ruby '3.1.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'aws-sdk-s3'
gem 'barnes'
gem 'bloomerang_api', '~> 1.0'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap3-datetimepicker-rails'
gem 'bootstrap-sass'
gem 'chartkick'
gem 'devise'
gem 'discard'
gem 'font-awesome-sass', '~> 5.15.1'
gem 'google-api-client'
gem 'haml'
gem 'httparty'
gem 'icalendar'
gem 'image_processing', '~> 1.12.2'
gem 'jquery-datatables-rails'
gem 'jquery-rails'
gem 'mini_magick'
gem 'momentjs-rails'
gem 'money-rails'
gem 'net-smtp'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'pg'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '>= 6.1.6.1'
gem 'rails_admin', '~> 2.2'
gem 'redis', '~> 4.3', '>= 4.3.1'
gem 'rest-client'
gem 'sass-rails', '>= 6'
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'simple_form'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

group :production do
  gem 'rails_12factor'
end

group :development do
  gem 'letter_opener_web'
  gem 'listen', '~> 3.2'
  gem 'rubocop'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'airborne'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'foreman'
  gem 'selenium-webdriver'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'timecop'
  gem 'webdrivers'
end

group :test do
  gem 'capybara'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'shoulda-matchers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
