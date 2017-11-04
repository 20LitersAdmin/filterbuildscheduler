class UsersController < ApplicationController
  def show
  	@user = User.find(params[:id])
    @past_events = @user.registrations.select{|r| r.event.end_time.past?}.map {|x| x.event}
  end

  def edit
  	@user = User.find(params[:id])
  end


  def delete
    @user = authorize User.find(params[:id])
    @user.delete
    redirect_to users_path
  end

end
