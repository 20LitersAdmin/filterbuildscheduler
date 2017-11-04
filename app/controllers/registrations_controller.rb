class RegistrationsController < ApplicationController
  def create
    if current_user
      Registration.create!(registration_params)
    else
      user = User.find_or_initialize_by(email: user_params[:email]) do |user|
        user.fname = user_params[:fname]
        user.lname = user_params[:lname]
      end

      user.save && sign_in(:user, user) if user.new_record?

      Registration.create!(event_id: params[:registration][:event_id], user_id: current_user.id)
    end

    redirect_to events_path
  end
  
  def edit
    @registration = Registration.find(params[:id])
  end

  def destroy
    @registration = authorize Registration.find(params[:id])
    @@registration.delete
    redirect_to event_path(@registration.event)
  end
  
  private

  def user_params
    params.require(:user).permit(:fname, :lname, :email)
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
