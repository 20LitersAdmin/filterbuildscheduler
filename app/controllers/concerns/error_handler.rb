module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  end

  def render_forbidden
    flash[:danger] = "You don't have permission"
    redirect_back(fallback_location: root_path)
  end
end
