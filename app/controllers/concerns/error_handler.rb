# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  end

  def render_forbidden
    if current_user
      flash[:danger] = 'You don\'t have permission.'
      redirect_back(fallback_location: root_path)
    else
      flash[:danger] = 'You need to sign in first.'
      redirect_to new_user_session_path(return_to: request.env['PATH_INFO'])
    end
  end

  def record_not_found
    return if params[:controller] == 'rails_admin/main'

    flash[:danger] = 'Nothing was found.'
    redirect_to root_path
  end
end
