class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception

  def waiver
    render partial: 'users/user_waiver_form'
  end
end
