# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :reload_rails_admin, if: :rails_admin_path?

  def waiver
    render partial: 'users/user_waiver_form', locals: { modal: false }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[fname lname])
  end

  private

  def reload_rails_admin
    models = %w[User Event Registration Location Technology Component Part Material Supplier Count Inventory]
    models.each do |m|
      RailsAdmin::Config.reset_model(m)
    end
    RailsAdmin::Config::Actions.reset

    load("#{Rails.root}/config/initializers/rails_admin.rb")
  end

  def rails_admin_path?
    controller_path =~ /rails_admin/ && Rails.env.development?
  end
end
