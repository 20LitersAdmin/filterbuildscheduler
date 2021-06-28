# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  def new
    # TODO: remove this handy method before deploy
    User.first.reset_password('password', 'password') if Rails.env.development?

    @custom_path = params[:return_to]
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    # if there's a custom_path, go to that.
    if resource_params[:custom_path].present?
      respond_with resource, location: resource_params[:custom_path]
    else
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  def update
    super
  end
end
