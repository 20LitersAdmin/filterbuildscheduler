# frozen_string_literal: true

# =====> Hello, Interviewers!
#
# My first attempt at syncing Gmail with our donor CRM was to not actually
# store records in my database at all.
#
# But I ran into issues with duplication. This model primarily ensures we
# can ignore duplicates.
#
# It also allows me to encapsulate the logic for data from Gmail turning
# into data for Kindful.
#
# Emails are only saved for 2 weeks so the database doesn't get bloated.

class Email < ApplicationRecord
  belongs_to :oauth_user

  validates :message_id, :gmail_id, presence: true, uniqueness: true
  validates :from, :to, presence: true
  validate :deny_internal_messages

  after_create :send_to_kindful, unless: -> { Rails.env.test? }

  scope :ordered, -> { order(datetime: :desc) }
  scope :stale, -> { where('datetime < ?', Time.now - 14.days) }
  scope :synced, -> { where.not(sent_to_kindful_on: nil) }

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

    email = where(message_id: message_id).first_or_initialize

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
    email.reload unless email.errors.any?
  end

  def send_to_kindful
    kf = KindfulClient.new

    temp_matched_emails = []
    temp_job_ids = []

    target_emails.each do |email_address, direction|
      next unless kf.email_exists_in_kindful?(email_address)

      org = Organization.find_by(email: email_address)
      response =
        if org.present?
          kf.import_company_w_email_note(email_address, self, direction, org.company_name)
        else
          kf.import_user_w_email_note(email_address, self, direction)
        end

      next if !response.ok? || response&.body.nil? || response&.body&.empty?

      temp_matched_emails << email_address
      temp_job_ids << response['id']
    end

    update_columns(sent_to_kindful_on: Time.now, matched_emails: temp_matched_emails, kindful_job_id: temp_job_ids) if temp_matched_emails.any?

    reload
  end

  def sync_msg
    return 'Not synced. No contact match.' if sent_to_kindful_on.nil?

    "Synced with #{matched_emails.join(', ')} at #{sent_to_kindful_on.strftime('%-m/%-d/%y %l:%M %P')}"
  end

  def sync_banner_color
    sent_to_kindful_on.present? ? 'success' : 'warning'
  end

  def synced?
    sent_to_kindful_on.present?
  end

  def synced_data
    attributes.slice('id', 'oauth_user_id', 'sent_to_kindful_on', 'matched_emails', 'kindful_job_id', 'gmail_id', 'message_id')
  end

  private

  def deny_internal_messages
    return false if from.blank? || to.blank?

    domains = Constants::Email::INTERNAL_DOMAINS
    address_domains = []

    # Email Regex for domain was:
    # /@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])/
    # which I think came from me pulling URI::MailTo::EMAIL_REGEXP apart to find just the domain portion?
    # Now it's just a simple "everything after @ until a period"
    (from + to).uniq.each do |address|
      address_domains << address.scan(/@[^.]+/)
    end

    external_domains = address_domains.flatten.reject { |addr| domains.include? addr }

    return true if external_domains.any?

    errors.add(:from, 'Internal Emails only!')

    false
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
