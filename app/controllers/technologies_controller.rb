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

    # Used for _material.haml#3
    @part_uids = @technology.quantities.keys.grep(/\AP/)

    material_uids = @technology.quantities.keys.grep(/\AM/)
    material_ids = []
    material_uids.each { |uid| material_ids << uid.tr('M', '').to_i }
    @materials = Material.where(id: material_ids)

    @assemblies = @technology.assemblies.prioritized
  end
end
