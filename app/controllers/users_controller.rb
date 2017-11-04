class UsersController < ApplicationController
  def show
  	@user = User.find(params[:id])
    @future_events = @user.registrations
                          .joins(:event)
                          .where('events.end_time > ?', Time.now)
                          .map(&:event)
    @past_events = @user.registrations
                        .joins(:event)
                        .where('events.end_time < ?', Time.now)
                        .map(&:event)
  end

  def edit
  	@user = User.find(params[:id])
  end

  def update
    @user = User.find params[:id]
    @user.update user_params
    redirect_to events_path
  end

  def delete
    @user = authorize User.find(params[:id])
    @user.delete
    redirect_to users_path
  end

  private

  def user_params
    params.require(:user).permit :fname,
                                  :lname,
                                  :email,
                                  :password,
                                  :password_confirmation
  end

end
