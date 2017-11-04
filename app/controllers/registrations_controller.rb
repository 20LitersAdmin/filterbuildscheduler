class RegistrationsController < ApplicationController
  def create
    Registration.create!(registration_params)
    redirect_to events_path
  end

  def registration_params
    params.require(:registration).permit :event_id,
                                         :user_id
  end
end
