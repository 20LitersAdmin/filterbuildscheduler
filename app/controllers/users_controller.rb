class UsersController < ApplicationController


  def delete
    @user = authorize User.find(params[:id])
    @user.delete
    redirect_to users_path
  end

end
