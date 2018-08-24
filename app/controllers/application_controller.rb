# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery

  before_action :configure_permitted_parameters, if: :devise_controller?

  def waiver
    render partial: 'users/user_waiver_form', locals: {modal: false}
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:fname, :lname])
  end
end
