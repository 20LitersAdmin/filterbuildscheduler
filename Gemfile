# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.0'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'aws-sdk-s3'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap3-datetimepicker-rails'
gem 'bootstrap-sass'
gem 'delayed_cron_job', '~> 0.7.2'
gem 'delayed_job', '~> 4.1'
gem 'delayed_job_active_record', '~> 4.1'
gem 'delayed_job_web'
gem 'devise'
gem 'discard'
gem 'font-awesome-rails'
gem 'google-api-client'
gem 'haml'
gem 'httparty'
gem 'icalendar'
gem 'jquery-datatables-rails'
gem 'jquery-rails'
gem 'mini_magick'
gem 'momentjs-rails'
gem 'money-rails'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'paranoia', '~> 2.4'
gem 'pg'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '~> 6.1.3.2'
gem 'rails_admin', '~> 2.0'
gem 'redis', '~> 4.3', '>= 4.3.1'
gem 'rest-client'
gem 'sass-rails', '>= 6'
gem 'simple_form'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

group :production do
  gem 'rails_12factor'
end

group :development, :test do
  gem 'airborne'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'foreman'
  gem 'timecop'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
end

group :development do
  gem 'letter_opener_web'
  gem 'listen', '~> 3.2'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
