class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery


  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def waiver
    render partial: 'users/user_waiver_form', locals: {modal: false}
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:fname, :lname])
  end

  def record_not_found
    flash[:warning] = "Nothing was found."
    redirect_to root_path
  end
end
