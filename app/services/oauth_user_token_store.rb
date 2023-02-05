# frozen_string_literal: true

# Token store needed for Google::Auth implementation
# if google-api-client is removed / degrades, we'll need this
# class OauthUserTokenStore < Google::Auth::TokenStore
  # attr_accessor :oauth_user

  # def initialize(oauth_user)
  #   super()
  #   @oauth_user = oauth_user
  # end

  # def load(id)
  #   @oauth_user.oauth_token
  # end

  # def store(id, token)
  #   @oauth_user.update_columns(oauth_token: token)
  # end

  # def delete(id)
  #   @oauth_user.update_columns(oauth_token: nil)
  # end
# end