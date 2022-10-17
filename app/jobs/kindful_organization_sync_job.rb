# frozen_string_literal: true

require 'sidekiq-scheduler'

class KindfulOrganizationSyncJob < ApplicationJob
  queue_as :kindful_job

  def perform(*_args)
    puts 'Syncing Organizations.'

    KindfulClient.new.query_organizations

    puts 'Done.'
  end

end
