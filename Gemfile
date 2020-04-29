# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.5.8'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'bootstrap-sass'
gem 'bootstrap3-datetimepicker-rails'
gem 'delayed_cron_job', '~> 0.7.2'
gem 'delayed_job', '~> 4.1'
gem 'delayed_job_active_record', '~> 4.1'
gem 'devise'
gem 'dotenv-rails'
gem 'font-awesome-rails'
gem 'httparty'
gem 'icalendar'
gem 'jquery-datatables-rails'
gem 'jquery-rails'
gem 'momentjs-rails'
gem 'money-rails'
gem 'paranoia', '~> 2.4'
gem 'pg', '~> 0.21'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '~> 5.2'
gem 'rails_admin', '~> 1.3.0'
gem 'rest-client'
gem 'sass-rails', '~> 5.0'
gem 'simple_form'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

group :production do
  gem 'rails_12factor'
end

group :development, :test do
  gem 'airborne'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'foreman'
  gem 'rubocop'
  gem 'timecop'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec-rails', '~> 3.7.2'
  gem 'rspec-retry'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
end

group :development do
  gem 'letter_opener_web'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'thin'
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
