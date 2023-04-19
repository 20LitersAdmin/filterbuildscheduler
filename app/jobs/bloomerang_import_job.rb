# frozen_string_literal: true

require 'sidekiq-scheduler'

class BloomerangImportJob < ApplicationJob
  queue_as :bloomerang_import_job

  def perform(total_sync: false)
    @total_sync = total_sync
    @bloom_client = BloomerangClient.new(:buildscheduler)

    if should_total_sync? || is_first_monday_of_the_month?
      puts 'Starting Bloomerang Import in Total Sync mode.'
      perform_total_sync
      # TEMP logging HACK
      LoggerMailer.notify(OauthUser.first, 'Bloomerang Import Job', 'The Bloomerang Import Job just ran in Total Sync mode')
    else
      puts 'Starting Bloomerang Import in Update mode.'
      perform_update
      # TEMP logging HACK
      LoggerMailer.notify(OauthUser.first, 'Bloomerang Import Job', 'The Bloomerang Import Job just ran in Update mode.')
    end
  end

  def perform_update
    last_modified = Constituent.last_modified

    puts "========================= Syncing Constituents last modified after #{last_modified}"

    @constituent_ids = @bloom_client.import_constituents!(last_modified:)

    puts "Synced all Constituents, found #{@constituent_ids.size} new/modified."

    return 'Done!' if @constituent_ids.none?

    @id_string = @constituent_ids.join('|')

    puts '========================= Syncing emails and phones for new/modified Constituents.'
    @bloom_client.import_emails!(constituent_ids: @id_string)
    @bloom_client.import_phones!(constituent_ids: @id_string)

    @bloom_client.write_primary_emails_to_constituents!(ids: @constituent_ids)
    @bloom_client.write_primary_phones_to_constituents!(ids: @constituent_ids)

    puts 'Done!'
  end

  def perform_total_sync
    puts '========================= Syncing All Constituents'

    @bloom_client.import_constituents!

    puts "Synced all Constituents, found #{@bloom_client.total_records} total."

    puts '========================= Syncing All Emails and Phones.'
    @bloom_client.import_emails!
    @bloom_client.import_phones!

    puts '========================= Setting Primary Emails and Phones.'
    @bloom_client.write_primary_emails_to_constituents!
    @bloom_client.write_primary_phones_to_constituents!

    puts 'Done!'
  end

  def is_first_monday_of_the_month?
    current_date = Date.current
    current_date == (current_date.beginning_of_month - 1.day).next_week
  end

  def should_total_sync?
    @total_sync ||
      Constituent.none? ||
      ConstituentEmail.none?
  end
end
