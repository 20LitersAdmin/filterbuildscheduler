# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger
OmniAuth.config.full_host = Rails.env.production? ? 'https://make.20liters.org' : 'http://localhost:3000'
OmniAuth.config.allowed_request_methods = %i[post get]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Rails.application.credentials.google_client_id, Rails.application.credentials.google_client_secret,
    {
      scope: 'email, profile, openid, gmail.readonly',
      name: 'google',
      access_type: 'offline'
    }
end
