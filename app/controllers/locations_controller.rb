class LocationsController < ApplicationController


  def delete
    @location = authorize Location.find(params[:id])
    @location.delete
    redirect_to locations_path
  end

end
