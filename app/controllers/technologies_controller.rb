# frozen_string_literal: true

class TechnologiesController < ApplicationController
  def index
    # select technology for /materials
    authorize @techs = Technology.status_worthy
  end

  def materials
    authorize @technology = Technology.find(params[:id])
  end
end
