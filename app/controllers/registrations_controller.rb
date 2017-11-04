class RegistrationsController < ApplicationController
  def create
    if current_user
      Registration.create!(registration_params)
    else
      user = User.find_or_create_by(email: user_params[:email]) do |user|
        user.name = user_params[:name]
      end

      Registration.create!(event_id: params[:registration][:event_id], user_id: user.id)
    end

    redirect_to events_path
  end

  private

  def registration_params
    params.require(:registration).permit(:event_id, :user_id)
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
