# frozen_string_literal: true

db_configuration = ActiveRecord::Base.configurations[Rails.env]
db_configuration.merge!('prepared_statements' => false)
ActiveRecord::Base.establish_connection(db_configuration)
