class TechnologiesController < ApplicationController

  def delete
    @tech = authorize Technology.find(params[:id])
    @tech.delete
    redirect_to technologies_path
  end

end
