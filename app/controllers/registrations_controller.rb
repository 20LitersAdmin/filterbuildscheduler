class RegistrationsController < ApplicationController
  def create
    if current_user
      Registration.create!(registration_params)
    else
      user = User.find_or_initialize_by(email: user_params[:email]) do |user|
        user.name = user_params[:name]
      end

      user.save && sign_in(:user, user) if user.new_record?

      Registration.create!(event_id: params[:registration][:event_id], user_id: current_user.id)
    end

    redirect_to events_path
  end

  def delete
    @reg = authorize Registration.find(params[:id])
    @reg.delete
    redirect_to registrations_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
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
