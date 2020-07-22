web: bundle exec puma -C config/puma.rb
worker: rake send_reminders && rake send_report && rake jobs:work
registration_worker: bundle exec sidekiq -c 2
