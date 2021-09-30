# frozen_string_literal: true

class TechnologiesController < ApplicationController
  before_action :set_technology, only: %i[items prices]
  before_action :set_bom_items, only: %i[items prices]

  def index
    authorize @techs = Technology.list_worthy
  end

  def prices; end

  def donation_list
    @quantity = params[:q].present? ? params[:q].to_i : 1
    @quantity_val = params[:q].to_i if params[:q].present?

    @technologies_select = Technology.list_worthy.pluck(:short_name, :id)
    # params[:tech] can be used to limit the donations needed
    tech_id_ary = broad_set_params.except(:q).keys

    # TODO: Part.kept; Material.kept
    @items = []
    if tech_id_ary.any?
      @selected_technologies = Technology.where(id: tech_id_ary)
      @selected_technologies.each do |technology|
        @items << technology.parts.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
        @items << technology.materials.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
      end
    else
      @selected_technologies = Technology.list_worthy
      @items << Part.not_made_from_materials.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
      @items << Material.all.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
    end
    @items.flatten!(1)
  end

  def label
    # page to print a full page of labels for one item
    @label = Label.new(@item.label_hash)
  end

  def labels
    authorize Technology
    # get 'labels', to: 'technologies#labels', as: 'labels'
    # page to select multiple items to print individual lables

    # TODO: Technology.kept.list_worthy; Component.kept etc.
    @technologies = Technology.list_worthy.pluck(:uid, :name)
    @components =   Component.all.order(:name).pluck(:uid, :name)
    @parts =        Part.all.order(:name).pluck(:uid, :name)
    @materials =    Material.all.order(:name).pluck(:uid, :name)
  end

  def labels_select
    authorize Technology

    if broad_set_params.empty?
      redirect_to labels_path
      flash[:danger] = 'No labels selected for printing.'
      return
    end

    @ary = []
    broad_set_params.each do |uid, _bool|
      item = uid.objectify_uid
      @ary << Label.new(item.label_hash) unless item.nil?
    end

    render 'labels_show'
  end

  private

  def set_technology
    authorize @technology = Technology.find(params[:id])
  end

  def objectify_uid_from_param
    authorize Technology
    uid = params[:uid]
    @item = uid.objectify_uid

    raise ActiveRecord::RecordNotFound unless @item.present?
  end

  def set_bom_items
    @quantity = params[:q].present? ? params[:q].to_i : 1
    @quantity_val = params[:q].to_i if params[:q].present?
    @assemblies = @technology.assemblies.ascending
    @materials = @technology.materials
    # Materials print which parts they are used to make.
    # But this list can include parts not related to @technology
    # So we compare material.parts & @part_uids
    @part_uids = @technology.quantities.keys.grep(/\AP/)
  end

  def broad_set_params
    params.except(
      :authenticity_token,
      :action,
      :controller,
      :DataTables_Table_0_length
    ).permit!
  end
end
