source 'https://rubygems.org'
ruby '2.4.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'pg'
gem 'dotenv-rails'
gem 'pundit'
gem 'simple_form'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'
gem "rails_admin_clone", "~> 0.0.6"
gem 'rails_admin'
gem 'devise'
gem 'simple_token_authentication', '~> 1.0'
gem 'bootstrap-sass'
gem 'jquery-rails'
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record", "~> 4.1"
gem "delayed_cron_job", "~> 0.7.2"
gem "paranoia", "~> 2.4"
gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', '~> 4.14.30'
gem 'font-awesome-rails'
gem 'rest-client'
gem 'stripe'
gem 'stripe_event'
gem 'pry-byebug'
gem 'money-rails'

group :production do
  gem 'puma'
  gem 'rails_12factor'
end

group :development, :test do

  gem 'rubocop'
  gem 'timecop'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'rspec'
  gem 'rspec-rails'
end

group :development do
  gem 'thin'
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'letter_opener_web'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

