web: /bin/bash -l -c "rails db:migrate && bundle exec puma -C config/puma.rb"
worker: /bin/bash -l -c "bundle exec sidekiq -C config/sidekiq.yml"
