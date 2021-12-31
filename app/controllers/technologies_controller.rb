# frozen_string_literal: true

class TechnologiesController < ApplicationController
  before_action :authorize_tech_class, except: %i[status]
  before_action :authorize_technology, only: %i[status]

  def donation_list
    # Table of parts and materials, filterable by technology
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

  def item_list
    # Item names alphabetically with UID (find UID by name)
    technologies = Technology.list_worthy.pluck(:uid, :name)
    components =   Component.active.order(:name).pluck(:uid, :name)
    parts =        Part.active.order(:name).pluck(:uid, :name)
    materials =    Material.active.order(:name).pluck(:uid, :name)

    @items = [technologies, components, parts, materials].flatten(1)
  end

  def item_lists
    # index of item lists:
    # donation_list - parts and materials, filterable by technology
    # setup_list - default to SAM3, show counts, by Component
    # item_list - Item names alphabetically with UID (find UID by name)
  end

  def label
    # page to print a full page of labels for one item
    @item = params[:uid].objectify_uid

    raise ActiveRecord::RecordNotFound unless @item.present?

    @label = Label.new(@item.label_hash)
    @print_navbar = true
  end

  def labels
    # page to select multiple items to print individual lables
    technologies = Technology.list_worthy.pluck(:uid, :name)
    components =   Component.active.order(:name).pluck(:uid, :name)
    parts =        Part.active.order(:name).pluck(:uid, :name)
    materials =    Material.active.order(:name).pluck(:uid, :name)

    @items = [technologies, components, parts, materials].flatten(1)
  end

  def labels_select
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

    @print_navbar = true

    render 'labels_show'
  end

  def status
    @goal = params[:goal].presence&.to_i || @technology.default_goal

    @remaining_need = [@goal - @technology.available_count, 0].max

    @assemblies = @technology.assemblies.without_price_only.ascending
  end

  def setup_list
    # default to SAM3, show counts, by Component
    @technology = Technology.find(3)
  end

  private

  def authorize_tech_class
    authorize Technology
  end

  def authorize_technology
    authorize @technology = Technology.find(params[:id])
  end

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
