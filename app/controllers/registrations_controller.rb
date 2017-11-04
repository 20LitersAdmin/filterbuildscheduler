class RegistrationsController < ApplicationController


  def delete
    @reg = authorize Registration.find(params[:id])
    @reg.delete
    redirect_to registrations_path
  end

end
