class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  acts_as_token_authentication_handler_for User
  
  def waiver
    render partial: 'users/user_waiver_form'
  end
end
