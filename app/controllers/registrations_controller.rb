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
    if params[:registration][:leader] == '1' && !User.find(params[:registration][:user_id]).is_leader?
      raise ActionController::BadRequest, "Cannot register as leader if you are not a leader" 
    end

    params.require(:registration).permit(:event_id,
                                         :user_id,
                                         :leader)
  end
end
