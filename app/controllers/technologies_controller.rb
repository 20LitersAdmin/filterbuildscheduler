# frozen_string_literal: true

class TechnologiesController < ApplicationController
  before_action :set_technology, except: :index
  before_action :set_items, only: %i[items prices]

  def index
    authorize @techs = Technology.list_worthy
  end

  def items
  end

  def prices; end

  private

  def set_technology
    authorize @technology = Technology.find(params[:id])
  end

  def set_items
    @quantity = params[:q].present? ? params[:q].to_i : 1
    @quantity_val = params[:q].to_i if params[:q].present?
    @assemblies = @technology.assemblies.ascending
    @materials = @technology.materials
    # Used for _material.haml#3
    @part_uids = @technology.quantities.keys.grep(/\AP/)
  end
end
