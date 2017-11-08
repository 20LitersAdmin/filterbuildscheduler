class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  def waiver
    render partial: 'users/user_waiver_form', locals: {modal: false}
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:fname, :lname])
  end

  private

  #permission defs
  def require_signin
  	unless !current_user.nil?
  		flash[:warning] = "Please sign in first."
  		redirect_to new_user_session_path
  	end
  end

  def require_self_or_admin(user)
  	unless current_user&.is_admin || user == current_user
  		flash[:warning] = "You don't have permission."
  		redirect_to root_path
  	end
  end

  def require_admin
  	unless current_user&.is_admin
  		flash[:warning] = "You don't have permission."
  		redirect_to root_path
  	end
  end

  def require_admin_or_leader
  	unless current_user&.is_admin || current_user&.is_leader
  		flash[:warning] = "You don't have permission."
  		redirect_to root_path
  	end
  end
end
