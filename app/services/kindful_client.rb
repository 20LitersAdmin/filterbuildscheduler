# frozen_string_literal: true

# =====> Hello, Interviewers!
# Once Ross Hunter taught me about APIs
# (see /app/controllers/webhooks_controller.rb), I got bold.
#
# Registering for a filter build event in this system should create a
# donor record in our donor CRM.
# Attending a filter build event should add a note to that donor's record.
#
# This allowed us to see how good we were at converting one-time event
# attendees into ongoing supporters of the organization.
#
# Phase 3 was the GmailClient (see /app/services/gmail_client.rb)

class KindfulClient
  include HTTParty
  attr_accessor :results, :env, :app

  def initialize(env: Rails.env.production? ? 'production' : 'sandbox')
    @query_token = ''
    @results = []
    # you can test in the sandbox by first setting @env to anything other than 'production'

    @env = env

    # based upon the method, @app is set to the contents
    # of the correct service. E.g. #import_transaction is used
    # by @kindful_causvox, so @app = kindful_causevox
    # this way headers can use @app globally
    @app = {}

    set_host
  end

  def set_host
    @host = "https://app#{'-sandbox' unless @env == 'production'}.kindful.com/api/v1"
  end

  def self.post(url, opts)
    # superceeds to HTTParty.post
    # don't actually send test data
    super(url, opts) unless Rails.env.test?
  end

  ### action methods:
  def import_transaction(transaction)
    # used by WebhooksController#stripe, which calls this method if the stripe data is for a CauseVox transaction
    @app = kindful_causevox

    set_host
    self.class.post(import_host, { headers: headers(@app[:token]), body: contact_w_transaction(transaction) })
  end

  def import_user(user)
    # used by User#update_kindful, which fires on after_save when contact fields have changed
    @app = kindful_filter_build
    set_host
    self.class.post(import_host, { headers: headers(@app[:token]), body: contact(user) })
  end

  def import_company_w_email_note(email_address, email, direction, company_name)
    # used by Email#send_to_kindful, when the email_address matches to an organization record
    @app = kindful_email
    set_host

    self.class.post(import_host, { headers: headers(@app[:token]), body: company_w_email_note(email_address, email, direction, company_name) })
  end

  def import_user_w_email_note(email_address, email, direction)
    # used by Email#send_to_kindful, when the email_address *does not* match to an organization record
    @app = kindful_email
    set_host

    self.class.post(import_host, { headers: headers(@app[:token]), body: contact_w_email_note(email_address, email, direction) })
  end

  def import_user_w_note(registration)
    # used by EventsController#update, when event report is submitted, all event.registrations.attended records call this
    @app = kindful_filter_build
    set_host

    self.class.post(import_host, { headers: headers(@app[:token]), body: contact_w_note(registration) })
  end

  def email_exists_in_kindful?(email)
    @app = kindful_email

    # This method is always hitting the Production site with Production credentials
    response = self.class.get(email_host(email), { headers: live_headers })

    response.parsed_response['exist']
  end

  def query_organizations
    # queries Kindful's API to get a list of companies
    @app = kindful_email
    set_host

    response = self.class.post(query_host, { headers: headers(@app[:token]), body: organizations_query })

    @results << response.parsed_response['results'] if response.parsed_response['results'].any?

    return unless response.parsed_response['has_more']

    @query_token = response.parsed_response['query_token']

    while response.parsed_response['has_more']
      response = self.class.post("#{query_host}?query_token=#{@query_token}", { headers: headers(@app[:token]) })
      @results << response.parsed_response['results'] if response.parsed_response['results'].any?
    end

    recreate_organizations
  end

  ### body methods:
  def contact(user)
    # create or update contact in Kindful
    # from import_user
    # add to 'Vol: Filter Builder group'
    group_name = 'Vol: Filter Builder'

    {
      data_format: 'contact',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'first_name_last_name_email',
        group: 'name'
      },
      groups: [group_name],
      data: [
        {
          id: user.id.to_s,
          first_name: user.fname,
          last_name: user.lname,
          email: user.email,
          primary_phone: user.phone,
          email_opt_in: user.email_opt_in,
          country: 'US',
          group_name => 'yes'
        }
      ]
    }.to_json
  end

  def company_w_email_note(email_address, email, direction, company_name)
    # used by EmailSyncJob
    # create or update company
    # add email as note record linked to company
    # direction: 'Received Email' || 'Sent Email'
    {
      data_format: 'contact_with_note',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        campaign: 'name',
        fund: 'name',
        contact: 'company_name_email'
      },
      data: [
        {
          # id: email.id.to_s,
          company_name: company_name,
          email: email_address,
          country: 'US',
          note_id: email.message_id,
          note_time: email.datetime,
          note_subject: email.subject,
          note_body: email.body,
          message_body: email.snippet,
          note_type: direction,
          note_sender_name: email.oauth_user.name,
          note_sender_email: email.oauth_user.email,
          campaign: @app[:campaign_name],
          fund: @app[:fund_name]
        }
      ]
    }.to_json
  end

  def contact_w_email_note(email_address, email, direction)
    # used by EmailSyncJob
    # create or update contact
    # add email as note record linked to contact
    # direction: 'Received Email' || 'Sent Email'
    {
      data_format: 'contact_with_note',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'email',
        campaign: 'name',
        fund: 'name'
      },
      data: [
        {
          # id: email.id.to_s,
          email: email_address,
          country: 'US',
          note_id: email.message_id.to_s,
          note_time: email.datetime,
          note_subject: email.subject,
          note_body: email.body,
          message_body: email.snippet,
          note_type: direction,
          note_sender_name: email.oauth_user.name,
          note_sender_email: email.oauth_user.email,
          campaign: @app[:campaign_name],
          fund: @app[:fund_name]
        }
      ]
    }.to_json
  end

  def contact_w_note(registration)
    # from import_user_w_note(registration)
    # create or update contact
    # adds a note about filter build event attendance

    role = registration.leader? ? 'Leader:' : 'Builder:'

    guests = registration.guests_attended.positive? ? "(#{registration.guests_attended} #{'guest'.pluralize(registration.guests_attended)})" : ''

    subject = "[Filter Build] #{role} #{registration.event.title} #{guests}"

    attendee = registration.user

    {
      data_format: 'contact_with_note',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'first_name_last_name_email',
        campaign: 'name',
        fund: 'name'
      },
      data: [
        {
          # id: registration.user.id.to_s,
          first_name: attendee.fname,
          last_name: attendee.lname,
          email: attendee.email,
          primary_phone: attendee.phone,
          email_opt_in: attendee.email_opt_in,
          country: 'US',
          note_id: registration.id.to_s,
          note_time: registration.event.end_time.to_s,
          note_subject: subject,
          note_type: 'Event',
          campaign: @app[:campaign_name],
          fund: @app[:fund_name]
        }
      ]
    }.to_json
  end

  def contact_w_transaction(charge)
    # from import_transaction
    # creates or updates a contact
    # creates a transaction (CauseVox transaction)
    {
      data_format: 'contact_with_transaction',
      action_type: 'create',
      data_type: 'json',
      match_by: {
        contact: 'first_name_last_name_email',
        campaign: 'name',
        fund: 'name'
      },
      data: [
        {
          transaction_time: charge.transaction_time,
          stripe_charge_id: charge.stripe_charge_id,
          amount_in_cents: charge.amount_in_cents,
          currency: charge.currency,
          transaction_note: charge.transaction_note,
          transaction_type: charge.transaction_type,
          card_type: charge.card_type,
          first_name: charge.first_name,
          last_name: charge.last_name,
          email: charge.email,
          addr1: charge.addr1,
          addr2: charge.addr2,
          city: charge.city,
          state: charge.state,
          postal: charge.postal,
          country: charge.country,
          acknowledged: 'false',
          campaign: @app[:campaign_name],
          fund: @app[:fund_name]
         }
      ]
    }.to_json
  end

  def organizations_query
    # from query_organizations
    # returns a collection of organizations with emails
    {
      query:
        [
          {
            or:
              [
                { by_group_id: '22330' },
                { by_group_id: '28657' },
                { by_group_id: '28658' },
                { by_group_id: '17846' }
              ]
          },
          { has_email: 'Yes' }
        ],
      columns: { contact: %w[company_name email donor_type] }
    }.to_json
  end

  def import_host
    # endpoint for importing data
    "#{@host}/imports"
  end

  def email_host(email)
    # endpoint for checking if an email exists in Kindful
    "https://app.kindful.com/api/v1/contacts/email_exist?email=#{email}"
  end

  def query_host
    # endpoint for querying data
    "#{@host}/contacts/query"
  end

  private

  def headers(token)
    {
      'Content-Type': 'application/json',
      'Authorization': "Token token=\"#{token}\""
    }
  end

  def kindful_filter_build
    {
      campaign_name: 'Filter Builds',
      fund_name: 'Contributions 40100',
      token: token(:buildscheduler)
    }
  end

  def kindful_causevox
    {
      campaign_name: 'CauseVox Transactions',
      fund_name: 'Special Events 40400',
      token: token(:causevox)
    }
  end

  def kindful_email
    {
      campaign_name: 'Contributions',
      fund_name: 'Contributions 40100',
      token: token(:gmailsync)
    }
  end

  def live_headers
    {
      'Content-Type': 'application/json',
      'Authorization': "Token token=\"#{Rails.application.credentials.kindful[:gmailsync][:production]}\""
    }
  end

  def recreate_organizations
    return unless @results.any?

    Organization.delete_all

    @results.flatten.each do |result|
      next if result['donor_type'] != 'Organization' && (result['email'].blank? || result['company_name'].blank?)

      Organization.create(company_name: result['company_name'], email: result['email'])
    end
  end

  def token(app_name)
    Rails.application
         .credentials
         .kindful[app_name][@env.to_sym]
  end
end
