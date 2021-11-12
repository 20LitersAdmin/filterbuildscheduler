# frozen_string_literal: true

class TechnologiesController < ApplicationController
  before_action :set_technology, only: %i[items prices]
  before_action :set_bom_items, only: %i[items prices]

  def donation_list
    @quantity = params[:q].present? ? params[:q].to_i : 1
    @quantity_val = params[:q].to_i if params[:q].present?

    @technologies_select = Technology.list_worthy.pluck(:short_name, :id)
    # params[:tech] can be used to limit the donations needed
    tech_id_ary = broad_set_params.except(:q).keys

    @items = []
    if tech_id_ary.any?
      @selected_technologies = Technology.active.where(id: tech_id_ary)
      @selected_technologies.each do |technology|
        @items << technology.parts.not_made_from_material.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
        @items << technology.materials.active.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
      end
    else
      @selected_technologies = Technology.list_worthy
      @items << Part.not_made_from_material.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
      @items << Material.active.joins(:supplier).pluck(:uid, :name, :'suppliers.name', :sku, :quantities, :price_cents)
    end
    @items.flatten!(1)
  end

  def label
    # page to print a full page of labels for one item
    @item = params[:uid].objectify_uid

    raise ActiveRecord::RecordNotFound unless @item.present?

    @label = Label.new(@item.label_hash)
  end

  def labels
    authorize Technology
    # page to select multiple items to print individual lables
    @technologies = Technology.list_worthy.pluck(:uid, :name)
    @components =   Component.active.order(:name).pluck(:uid, :name)
    @parts =        Part.active.order(:name).pluck(:uid, :name)
    @materials =    Material.active.order(:name).pluck(:uid, :name)
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

  def broad_set_params
    # used for labels_select and donation_list
    params.except(
      :authenticity_token,
      :action,
      :controller,
      :DataTables_Table_0_length
    ).permit!
  end
end
