source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'pg'
gem 'pundit'
gem 'dotenv-rails'
gem 'simple_form'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'
gem 'rails_admin'
gem 'devise'
gem 'simple_token_authentication', '~> 1.0'
gem 'bootstrap-sass'
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record", "~> 4.1"
gem "delayed_cron_job", "~> 0.7.2"

group :production do
  gem 'puma'
end

group :development, :test do
  gem 'pry-byebug'
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
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

