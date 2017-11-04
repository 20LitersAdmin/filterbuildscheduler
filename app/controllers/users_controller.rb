class UsersController < ApplicationController
  def show
  	@user = User.find(params[:id])
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
