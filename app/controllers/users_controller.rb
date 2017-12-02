class UsersController < ApplicationController

  before_action only: [:show, :edit, :update, :delete] do
    find_and_authorize_user
  end

  def show
    if @user.has_no_password
      flash[:warning] = "You haven't set your password yet, please do so now."
    end
    @leading_events = @user.registrations
                           .where(leader: true)
                           .joins(:event)
                           .where('events.end_time > ?', Time.now)
                           .map(&:event)
    @attending_events = @user.registrations
                             .where(leader: false)
                             .joins(:event)
                             .where('events.end_time > ?', Time.now)
                             .map(&:event)
    @lead_events = @user.registrations
                         .where(leader: true)
                         .joins(:event)
                         .where('events.end_time < ?', Time.now)
                         .map(&:event)
    @attended_events = @user.registrations
                             .where(leader: false)
                             .joins(:event)
                             .where('events.end_time < ?', Time.now)
                             .map(&:event)
  end

  def edit
    if @user.has_no_password
      flash[:warning] = "You haven't set your password yet, please do so now."
    end
  end

  def update
    if @user.update(user_params)
      flash[:success] = "Info updated!"
      redirect_to events_path
    else
      render 'edit'
    end
  end

  def delete
    @user.delete
    flash[:danger] = "User deleted"
    redirect_to users_path
  end

  private

  def find_and_authorize_user
    @user = User.find params[:id]
    authorize @user
  end

  def user_params
    params.require(:user).permit :fname,
                                  :lname,
                                  :email,
                                  :password,
                                  :password_confirmation
  end

end
