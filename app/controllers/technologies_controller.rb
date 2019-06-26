# frozen_string_literal: true

class TechnologiesController < ApplicationController
  def index
    # select technology for /materials
    authorize @techs = Technology.list_worthy
  end

  def items
    authorize @technology = Technology.find(params[:id])

    @quantity = params[:q].present? ? params[:q].to_i : 1
    @quantity_val = params[:q].to_i if params[:q].present?
    @ignore_component_counts = params[:i] == '1'

    @components = @technology.components.required

    # Parts in technology that are not part of a component
    @component_parts_ids = @components.includes(:parts).map { |c| c.parts.map(&:id) }.flatten!
    @loose_parts = @technology.parts.where.not(id: @component_parts_ids)
  end
end
