# frozen_string_literal: true

class Email < ApplicationRecord
  belongs_to :oauth_user

  validates :message_id, :gmail_id, presence: true, uniqueness: true
  validates :from, :to, presence: true
  validate :deny_internal_messages

  before_create :check_for_organization

  after_create :send_to_kindful

  scope :ordered, -> { order(datetime: :desc) }
  scope :stale, -> { where('datetime < ?', Time.now - 14.days) }
  scope :synced, -> { where.not(sent_to_kindful_on: nil) }

  def self.from_gmail(response, body_data, oauth_user)
    message_id = cleanup_text response.payload.headers.select { |header| header.name.downcase == 'message-id' }.first&.value

    return if message_id.nil?

    email = where(message_id: message_id).first_or_initialize

    return email unless email.new_record?

    email.tap do |e|
      e.oauth_user = oauth_user
      e.gmail_id   = response.id
      e.snippet    = response.snippet.squish
      e.from       = email_address_from_text response.payload.headers.select { |header| header.name.downcase == 'from' }.first&.value
      e.to         = email_address_from_text response.payload.headers.select { |header| header.name.downcase == 'to' }.first&.value
      e.subject    = cleanup_text response.payload.headers.select { |header| header.name.downcase == 'subject' }.first&.value
      e.datetime   = Time.parse(response.payload.headers.select { |header| header.name.downcase == 'date' }.first&.value)
      e.body       = body_data
    end

    email.save
    email.reload unless email.errors.any?
  end

  def check_for_organization
    # TODO
    organization == true if Organization.where(email: target_emails).any?
  end

  def send_to_kindful
    kf = KindfulClient.new

    temp_matched_emails = []
    temp_job_ids = []

    target_emails.each do |email_address, direction|
      next unless kf.email_exists_in_kindful?(email_address)

      response = kf.import_user_w_email_note(email_address, self, direction)

      next if response['status'] == 'error'

      temp_matched_emails << email_address
      temp_job_ids << response['id']
    end
    update_columns(sent_to_kindful_on: Time.now, matched_emails: temp_matched_emails, kindful_job_id: temp_job_ids) if temp_matched_emails.any?

    reload
  end

  def self.cleanup_text(text)
    return if text.nil?

    text.gsub(/[<>\\"]/, '')
  end

  def self.email_address_from_text(text)
    return if text.nil?

    text.scan(/[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*/)
  end

  def sync_msg
    return 'Not synced. No contact match.' if sent_to_kindful_on.nil?

    "Synced with #{matched_emails.join(', ')} at #{sent_to_kindful_on.strftime('%-m/%-d/%y %l:%M %P')}"
  end

  def sync_banner_color
    return 'success' if sent_to_kindful_on.present?

    'warning'
  end

  def synced?
    sent_to_kindful_on.present?
  end

  def synced_data
    attributes.slice('id', 'oauth_user_id', 'sent_to_kindful_on', 'matched_emails', 'kindful_job_id', 'gmail_id', 'message_id')
  end

  def deny_internal_messages
    errors.add(:from, 'blank!') if from.blank?
    errors.add(:to, 'blank!') if to.blank?

    return if from.blank? || to.blank?

    domains = Constants::Email::INTERNAL_DOMAINS

    address_domains = []
    (from + to).uniq.each do |address|
      address_domains << address.scan(/@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])/)
    end

    external_domains = address_domains.flatten.reject { |addr| domains.include? addr }

    return if external_domains.any?

    errors.add(:from, 'Internal Emails only!')
  end

  def target_emails
    # If I sent the email, include everyone I sent it to
    # If I received the email, include the person who sent it to me
    if from.include? oauth_user.email
      email_addresses = to
      direction = 'Received Email'
    else
      email_addresses = from
      direction = 'Sent Email'
    end

    ary = []

    email_addresses.each do |email_address|
      ary << [email_address, direction]
    end

    # [[email, direction], [email, direction]]
    ary
  end
end
