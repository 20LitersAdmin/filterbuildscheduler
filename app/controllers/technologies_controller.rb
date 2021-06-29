# frozen_string_literal: true

class TechnologiesController < ApplicationController
  def index
    authorize @techs = Technology.list_worthy
  end

  def items
    authorize @technology = Technology.find(params[:id])

    @quantity = params[:q].present? ? params[:q].to_i : 1

    @quantity_val = params[:q].to_i if params[:q].present?

    @ignore_component_counts = params[:i] == '1'

    @components = @technology.components
    @parts = @technology.parts
  end

  def tree
    authorize @technology = Technology.find(params[:id])

    @assemblies = @technology.assemblies.prioritized

    @materials_parts_ary = []
  end
end
