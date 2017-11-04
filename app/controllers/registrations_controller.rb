class RegistrationsController < ApplicationController


  def create
    Registration.create!(registration_params)
    redirect_to events_path
  end

  def delete
    @reg = authorize Registration.find(params[:id])
    @reg.delete
    redirect_to registrations_path
  end

  def registration_params
    params.require(:registration).permit :event_id,
                                         :user_id
  end
end
