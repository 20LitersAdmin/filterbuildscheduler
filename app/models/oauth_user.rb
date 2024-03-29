# frozen_string_literal: true

# require 'googleauth/web_user_authorizer'
# require 'googleauth/token_store'

class OauthUser < ApplicationRecord
  has_many :emails, dependent: :destroy

  validates :oauth_id, :oauth_token, uniqueness: true, allow_blank: true

  scope :to_sync, -> { where(sync_emails: true) }
  scope :ordered_by_id, -> { order(:id) }

  attr_accessor :source

  # if google-api-client is removed / degrades, we'll need this
  # SCOPES = %w[https://www.googleapis.com/auth/gmail.readonly].freeze

  def self.from_omniauth(auth)
    oauth_user =
      where(email: auth.info.email).first_or_initialize.tap do |user|
        user.name = auth.info.name
        user.oauth_id = auth.uid
        user.oauth_provider = auth.provider
        user.oauth_token = auth.credentials.token
        user.oauth_refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token.present?
        user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      end

    oauth_user.save
    oauth_user.reload
  end

  def authorization
    Google::APIClient::ClientSecrets.new(
      {
        web:
          {
            access_token: oauth_token,
            refresh_token: oauth_refresh_token,
            client_id: Rails.application.credentials.google_client_id,
            client_secret: Rails.application.credentials.google_client_secret
          }
      }
    ).to_authorization

    # if google-api-client is removed / degrades, we'll need this
    # client_id = Rails.application.credentials.google_client_id
    # client_secret = Rails.application.credentials.google_client_secret
    # callback_uri = "/auth/google_oauth2/callback"
    #
    # Google::Auth::UserAuthorizer.new(
    #   client_id,
    #   SCOPES,
    #   OauthUserTokenStore.new(self),
    #   callback_uri
    # )
  end

  def oauth_expired?
    return true if oauth_expires_at.nil?

    oauth_expires_at < Time.now
  end

  def oauth_remaining
    return 0 if oauth_expires_at.nil?

    ((oauth_expires_at - Time.now) / 1.minutes).to_i
  end

  def email_service
    update_columns(oauth_error_message: nil) if oauth_error_message.present?
    # https://github.com/googleapis/google-api-ruby-client/blob/main/generated/google-apis-gmail_v1/lib/google/apis/gmail_v1/service.rb
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = authorization

    refresh_authorization! if oauth_expired?

    @service
  end

  def refresh_authorization!
    email_service if @service.nil?

    begin
      response = @service.authorization.refresh!
      new_expiry = Time.now + response['expires_in']
      update_columns(oauth_expires_at: new_expiry, oauth_token: response['access_token'])
    rescue Signet::AuthorizationError => e
      update_columns(oauth_error_message: e.message)
    end
  end

  def details
    as_json(only: %w[id sync_emails oauth_id oauth_expires_at last_email_sync manual_query oauth_error_message]).symbolize_keys!
  end

  def quick_details
    as_json(only: %w[sync_emails last_email_sync oauth_error_message]).symbolize_keys!
  end
end
