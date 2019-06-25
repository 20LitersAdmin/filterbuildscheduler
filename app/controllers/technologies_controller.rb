# frozen_string_literal: true

class TechnologiesController < ApplicationController
  def index
    # select technology for /materials
    authorize @techs = Technology.list_worthy
  end

  def items
    authorize @technology = Technology.find(params[:id])

    @components = @technology.components.required
  end
end
