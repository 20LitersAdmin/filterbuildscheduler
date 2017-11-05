class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  def waiver
    render partial: 'users/user_waiver_form'
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:fname, :lname])
  end

  def current_user_and_is_admin
    current_user && current_user.is_admin
  end
end
