# frozen_string_literal: true

require 'bloomerang'

# Constituent ID: 8300545 == Chip TestingForm
# email 14696
class BloomerangClient
  attr_reader :response, :total_records, :last_modified, :created_record_ids, :app, :bloomerang

  # app options:
  # :buildscheduler
  # :gmailsync
  # :causevoxsync
  def initialize(app)
    @app = app
    @bloomerang = Bloomerang
    @response = {}
    @total_records = 0
    @created_record_ids = []
    @last_modified = ''

    configure_bloomerang

    @api_key = @bloomerang.configuration.api_key
  end

  # Can use Constituent.last_modified
  def import_constituents!(batch_size: 50, last_modified: '', type: '')
    # Allow @last_modified to carry through to #import_emails! and #import_phones!
    # if passed in here.
    @last_modified = last_modified

    batch_get_constituents(last_modified:, type:, take: batch_size)

    return if @batch.empty?

    import_batch_of_constituents!(@batch)

    current_ids = Constituent.all.pluck(:id) if @last_modified.present?

    while @total_records > (@batch_start + @batch_result_count)
      @batch_start += @batch_result_count
      batch_get_constituents(skip: @batch_start, take: @batch_result_count, last_modified:, type:)
      import_batch_of_constituents!(@batch)
    end

    if @last_modified.present?
      @created_record_ids = Constituent.all.pluck(:id) - current_ids
    else
      @total_records
    end
  end

  def import_emails!(batch_size: 50, constituent_ids: '')
    batch_get_emails(take: batch_size, constituent_ids:)

    return if @batch.empty?

    import_batch_of_emails!(@batch)

    current_ids = ConstituentEmail.all.pluck(:id)

    while @total_records > (@batch_start + @batch_result_count)
      @batch_start += @batch_result_count
      batch_get_emails(skip: @batch_start, take: @batch_result_count)
      import_batch_of_emails!(@batch)
    end

    if @last_modified.present?
      @created_record_ids = ConstituentEmail.all.pluck(:id) - current_ids
    else
      @total_records
    end
  end

  def import_phones!(batch_size: 50, constituent_ids: '')
    batch_get_phones(take: batch_size, constituent_ids:)

    return if @batch.empty?

    import_batch_of_phones!(@batch)

    current_ids = ConstituentPhone.all.pluck(:id)

    while @total_records > (@batch_start + @batch_result_count)
      @batch_start += @batch_result_count
      batch_get_phones(skip: @batch_start, take: @batch_result_count)
      import_batch_of_phones!(@batch)
    end

    if @last_modified.present?
      @created_record_ids = ConstituentPhone.all.pluck(:id) - current_ids
    else
      @total_records
    end
  end

  # interaction_types
  # :became_leader
  # :skip
  def create_from_user(user, interaction_type: nil)
    # merge the Constituent
    @respone = @bloomerang::Constituent.create(user.as_bloomerang_constituent)

    return if interaction_type == :skip

    # capture the new/update Constituent ID
    constituent_id = @response['Id']

    # Translates to: user.became_leader_interaction(constituent_id)
    body = user.__send__("#{interaction_type}_interaction".to_sym, constituent_id)

    @bloomerang::Interaction.create(body)
  end

  # interaction_types
  # :attended_event
  # :skip
  def create_from_registration(registration, interaction_type: nil)
    # merge the Constituent
    @respone = @bloomerang::Constituent.create(registration.user.as_bloomerang_constituent)

    return if interaction_type == :skip

    # capture the new/update Constituent ID
    constituent_id = @response['Id']

    # Translates to: registration.attended_event_interaction(constituent_id)
    body = registration.__send__("#{interaction_type}_interaction".to_sym, constituent_id)

    @bloomerang::Interaction.create(body)
  end

  def create_from_causevox(charge)
    # charge is an instance of StripeCharge

    # merge the Constituent
    @response = @bloomerang::Constituent.create(charge.as_bloomerang_constituent)

    # capture the new/update Constituent ID
    constituent_id = @response['Id']

    # create the Transaction using the Constituent ID
    @bloomerang::Transaction.create(charge.as_bloomerang_transaction(constituent_id))
  end

  def create_from_email(email_as_interaction)
    @bloomerang::Interaction.create(email_as_interaction)
  end

  def write_primary_emails_to_constituents!(ids: [])
    records = ids.empty? ConstituentEmail | ConstituentEmail.where(id: ids)

    primary_emails = records.only_primaries.select(:constituent_id, :value)

    primary_emails.each do |email|
      Constituent.where(id: email.constituent_id).update(primary_email: email.value)
    end
  end

  def write_primary_phones_to_constituents!(ids: [])
    records = ids.empty? ConstituentPhone | ConstituentPhone.where(id: ids)

    primary_phones = records.only_primaries.select(:constituent_id, :value)

    primary_phones.each do |phone|
      Constituent.where(id: phone.constituent_id).update(primary_phone: phone.value)
    end
  end

  def search_for_appeal(appeal_name)
    response_one = @bloomerang::Appeal.fetch({ search: appeal_name, isActive: true })
    response_two = @bloomerang::Appeal.fetch({ search: appeal_name, isActive: false })

    response_one['Results'] + response_two['Results']
  end

  def create_appeal(appeal_name)
    body = {
      'Name': appeal_name,
      'IsActive': true
    }

    @bloomerang::Appeal.create(body)
  end

  def set_appeal_to_active(id)
    @bloomerang::Appeal.update(id, { 'IsActive': true })
  end

  protected

  ## Constituent batching
  def batch_get_constituents(skip: 0, take: 50, last_modified: '', type: '')
    params = {
      'skip': skip,
      'take': take
    }
    params['lastModified'] = last_modified if last_modified.present?
    params['type'] = type if type.present?

    @response = @bloomerang::Constituent.fetch(params)
    @total_records = @response['TotalFiltered']
    @batch_start = @response['Start']
    @batch_take = take
    @batch_result_count = @response['ResultCount']
    @batch = @response['Results']
  end

  def import_batch_of_constituents!(batch)
    Constituent.upsert_all(build_constituent_array(batch), unique_by: :id)
  end

  def build_constituent_array(response)
    ary = []
    response.each do |hash|
      next if hash.empty?

      timestamps = hash['AuditTrail']
      ary << {
        id: hash['Id'],
        name: hash['FullName'],
        created_at: Date.parse(timestamps['CreatedDate']),
        updated_at: Date.parse(timestamps['LastModifiedDate'])
      }
    end

    ary
  end

  ## Email batching
  def batch_get_emails(skip: 0, take: 50, constituent_ids: '')
    params = { 'skip': skip, 'take': take }
    params['constituent'] = constituent_ids if constituent_ids.present?

    @response = @bloomerang::Email.fetch(params)

    @total_records = @response['TotalFiltered']
    @batch_start = @response['Start']
    @batch_take = take
    @batch_result_count = @response['ResultCount']
    @batch = @response['Results']
  end

  def import_batch_of_emails!(batch)
    ConstituentEmail.upsert_all(build_email_array(batch), unique_by: :id)
  end

  def build_email_array(response)
    ary = []
    response.each do |hash|
      next if hash.empty? || hash['IsBad']

      ary << {
        id: hash['Id'],
        value: hash['Value'],
        constituent_id: hash['AccountId'],
        is_primary: hash['IsPrimary'],
        email_type: hash['Type']
      }
    end

    ary
  end

  ## Phone batching
  def batch_get_phones(skip: 0, take: 50, constituent_ids: '')
    params = { 'skip': skip, 'take': take }
    params['constituent'] = constituent_ids if constituent_ids.present?

    @response = @bloomerang::Phone.fetch(params)

    @total_records = @response['TotalFiltered']
    @batch_start = @response['Start']
    @batch_take = take
    @batch_result_count = @response['ResultCount']
    @batch = @response['Results']
  end

  def import_batch_of_phones!(batch)
    ConstituentPhone.upsert_all(build_phone_array(batch), unique_by: :id)
  end

  def build_phone_array(response)
    ary = []
    response.each do |hash|
      next if hash.empty?

      ary << {
        id: hash['Id'],
        value: hash['Number'],
        constituent_id: hash['AccountId'],
        is_primary: hash['IsPrimary'],
        phone_type: hash['Type']
      }
    end

    ary
  end

  def configure_bloomerang
    @bloomerang.configure do |config|
      config.api_key = app_api_key
      # Can override url if necessary
      # config.api_url = Rails.application.credentials.dig(:bloomerang, :api_url)
    end
  end

  def app_api_key
    Rails.application.credentials.dig(:bloomerang, @app)
  end
end
