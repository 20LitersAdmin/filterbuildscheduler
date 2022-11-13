# frozen_string_literal: true

namespace :db do
  namespace :reset do
    desc 'Drop, create, migrate (not schema:load) and seed'
    task hard: %w[db:drop db:create db:migrate db:seed]

    desc 'Dump seeds, then drop, create, migrate (not schema:load) and seed'
    task complete: %w[db:seed:dump db:drop db:create db:migrate db:seed]
  end
end
