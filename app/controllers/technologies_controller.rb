# frozen_string_literal: true

class TechnologiesController < ApplicationController
  before_action :set_technology, except: %i[index label labels labels_select]
  before_action :set_bom_items, only: %i[items prices]

  def index
    authorize @techs = Technology.list_worthy
  end

  def items; end

  def prices; end

  def label
    authorize Technology
    # get 'label', to: 'technologies#label', as: 'label'
    # page to print a full page of labels for one item
    uid = params[:uid]
    item = uid.objectify_uid

    raise ActiveRecord::RecordNotFound unless item.present?

    @label = Label.new(item.label_hash)
  end

  def labels
    authorize Technology
    # get 'labels', to: 'technologies#labels', as: 'labels'
    # page to select multiple items to print individual lables

    # TODO: Technology.kept.list_worthy; Component.kept et. al
    @technologies = Technology.list_worthy.pluck(:uid, :name)
    @components =   Component.all.order(:name).pluck(:uid, :name)
    @parts =        Part.all.order(:name).pluck(:uid, :name)
    @materials =    Material.all.order(:name).pluck(:uid, :name)
  end

  def labels_select
    authorize Technology

    if labels_select_params.empty?
      redirect_to labels_path
      flash[:danger] = 'No labels selected for printing.'
      return
    end

    @ary = []
    labels_select_params.each do |uid, _bool|
      item = uid.objectify_uid
      @ary << Label.new(item.label_hash) unless item.nil?
    end

    render 'labels_show'
  end

  private

  def set_technology
    authorize @technology = Technology.find(params[:id])
  end

  def set_bom_items
    @quantity = params[:q].present? ? params[:q].to_i : 1
    @quantity_val = params[:q].to_i if params[:q].present?
    @assemblies = @technology.assemblies.ascending
    @materials = @technology.materials
    # Used for _material.haml#3
    @part_uids = @technology.quantities.keys.grep(/\AP/)
  end

  def labels_select_params
    params.except(
      :authenticity_token,
      :action,
      :controller,
      :DataTables_Table_0_length
    ).permit!
  end
end
