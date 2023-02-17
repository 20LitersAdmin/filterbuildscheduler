# frozen_string_literal: true

require 'net/http'
require 'uri'

namespace :db do
  desc 'Downloads the Production database from Railway and loads the data into development'
  task parity: :environment do
    # check for psql installed
    unless system('psql -V')
      puts '===> psql not found or not installed'
      return
    end

    puts '===> Performing hard reset of the the dev database'

    `rails db:reset:hard`

    puts '===> Starting the copy via pg_dump'

    pg_url = Rails.application.credentials.railway[:pg][:url]

    `pg_dump -a -F t -x -v --dbname=#{pg_url} > latest_dump`

    puts '===> Got the production database, starting restoration'

    pg_vars = ActiveRecord::Base.connection_db_config.configuration_hash

    `pg_restore -a -O -F t -x -v --disable-triggers --dbname=postgresql://#{pg_vars[:user]}@127.0.0.1:#{pg_vars[:port]}/#{pg_vars[:database]} latest_dump`

    puts '===> Restored the production database to development'

    `rm latest_dump`
  end
end
