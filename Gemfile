source 'https://rubygems.org'
ruby '2.4.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'pg', "~> 0.21"
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
gem 'bootstrap-sass'
gem 'jquery-rails'
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record", "~> 4.1"
gem "delayed_cron_job", "~> 0.7.2"
gem "paranoia", "~> 2.4"
gem 'momentjs-rails'
gem 'bootstrap3-datetimepicker-rails'
gem 'font-awesome-rails'
gem 'rest-client'
gem 'pry-byebug'
gem 'money-rails'
gem 'icalendar'
gem 'jquery-datatables-rails'
gem 'httparty'


group :production do
  gem 'puma'
  gem 'rails_12factor'
end

group :development, :test do
  gem 'rubocop'
  gem 'timecop'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'squasher'
  gem 'foreman'
  gem 'airborne'
end

group :test do
  gem 'rspec'
  gem 'rspec-rails', '~> 3.7.2'
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
  gem 'capybara'
end

group :development do
  gem 'thin'
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'letter_opener_web'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

