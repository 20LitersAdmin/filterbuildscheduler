# frozen_string_literal: true

# TODO: HERE: I changed a lot, does this still work as expected?

class Email < ApplicationRecord
  belongs_to :oauth_user

  validates :message_id, :gmail_id, presence: true, uniqueness: true
  validates :from, :to, presence: true
  validate :deny_internal_messages
  validate :deny_unmatched_messages

  before_create :match_to_constituents

  after_create :send_to_crm

  scope :ordered, -> { order(datetime: :desc) }
  scope :stale, -> { where('datetime < ?', Time.now - 14.days) }
  scope :synced, -> { where.not(sent_to_kindful_on: nil) }

  # TODO: TEMP cleanup, remove after one production use
  def self.remove_if_unmatched!
    all.each do |record|
      record.__send__(:match_to_constituents)

      if record.matched_constituents.any?
        record.save
      else
        record.delete
      end
    end
  end

  def self.cleanup_text(text)
    return if text.nil?

    text.gsub(/[<>\\"]/, '')
  end

  def self.email_address_from_text(text)
    return if text.nil?

    text.scan(Constants::Email::REGEX)
  end

  def self.from_gmail(response, body_data, oauth_user)
    message_id = cleanup_text response.payload
                                      .headers
                                      .select { |header| header.name.downcase == 'message-id' }
                                      .first&.value

    from_emails = email_address_from_text response.payload
                                                  .headers
                                                  .select { |header| header.name.downcase == 'from' }
                                                  .first&.value

    to_emails = email_address_from_text response.payload
                                                .headers
                                                .select { |header| header.name.downcase == 'to' }
                                                .first&.value
    return if message_id.nil?

    email = where(message_id:).first_or_initialize

    return email unless email.new_record?

    email.tap do |e|
      e.oauth_user = oauth_user
      e.gmail_id   = response.id
      e.snippet    = response.snippet.squish
      e.from       = from_emails
      e.to         = to_emails
      e.subject    = cleanup_text response.payload
                                          .headers
                                          .select { |header| header.name.downcase == 'subject' }
                                          .first&.value
      e.body       = body_data
      e.datetime   = Time.parse(
        response.payload
          .headers
          .select { |header| header.name.downcase == 'date' }
          .first&.value
      )
    end

    email.save
    email.reload if email.errors.none?
  end

  def send_to_crm
    return if sent_to_crm_on.present?

    job_ids = []

    matched_constituents&.each do |constituent_id|
      response = BloomerangJob.perform_later(:gmailsync, :create_from_email, as_bloomerang_interaction(constituent_id))

      next if !response.ok? || response&.body.nil? || response&.body&.empty?

      job_ids << response['id']
    end

    update_columns(sent_to_crm_on: Time.now, crm_job_id: job_ids) if job_ids.any?

    reload
  end

  def sync_msg
    return 'Not synced. No contact match.' if sent_to_crm_on.nil?

    "Synced with #{constituent_names} at #{sent_to_crm_on.strftime('%-m/%-d/%y %l:%M %P')}"
  end

  def sync_banner_color
    sent_to_crm_on.present? ? 'success' : 'warning'
  end

  def synced?
    sent_to_crm_on.present?
  end

  def synced_data
    attributes.slice('id', 'oauth_user_id', 'sent_to_crm_on', 'matched_emails', 'crm_job_id', 'gmail_id', 'message_id')
  end

  def constituent_id_for_email(email_address)
    Constituent.find_by(primary_email: email_address)&.id ||
      ConstituentEmail.find_by(value: email_address)&.constituent&.id
  end

  def constituent_names
    Constituent.where(id: matched_constituents).pluck(:name).join(', ')
  end

  private

  def deny_internal_messages
    return false if from.blank? || to.blank?

    domains = Constants::Email::INTERNAL_DOMAINS
    address_domains = []

    (from + to).uniq.each do |address|
      address_domains << address.scan(/@[^.]+/)
    end

    external_domains = address_domains.flatten.reject { |addr| domains.include? addr }

    return true if external_domains.any?

    errors.add(:from, 'Internal Emails only!')

    false
  end

  def deny_unmatched_messages
    match_to_constituents

    return true if matched_constituents.any?

    errors.add(:from, 'No matches in database!')

    false
  end

  def match_to_constituents
    if from&.include? oauth_user.email
      email_addresses = to
      self.direction = 'received'
    elsif to&.include? oauth_user.email
      email_addresses = from
      self.direction = 'sent'
    end

    ary = []

    email_addresses&.each do |email_address|
      constituent_id = constituent_id_for_email(email_address)
      ary << constituent_id
    end

    self.matched_constituents = ary.compact.uniq
  end

  def as_bloomerang_interaction(constituent_id)
    {
      'AccountId': constituent_id.to_i,
      'Date': datetime.to_date.iso8601,
      'Channel': channel,
      'Purpose': 'ImpactCultivation',
      'Subject': "#{direction.upcase_first}: #{snippet}",
      'Note': body,
      'IsInbound': direction == 'sent'
    }.as_json
  end
end
