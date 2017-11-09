class LocationsController < ApplicationController


  def delete
    @location = authorize Location.find(params[:id])
    @location.delete
    redirect_to locations_path
  end

  def route_error
    flash[:danger] = "That's not a real place."
    redirect_to root_path
  end

end
