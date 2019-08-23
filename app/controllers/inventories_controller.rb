# frozen_string_literal: true

class InventoriesController < ApplicationController
  def index
    @latest = Inventory.latest
    @inventories = Inventory.former

    authorize @latest
  end

  def show
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| - c.name }

    if @inventory.type_for_params == 'manual'
      # show only what's ready for shipping
      @primary_components = Component.where(completed_tech: true).map(&:id)
      @primary_component_counts = @inventory.counts.where(component_id: @primary_components).sort_by { |c| - c.name }
    else
      # show only what's changed
      @diff_counts = @inventory.counts.where.not(user_id: nil).sort_by { |c| - c.name }
    end

    @event = Event.find(@inventory.event_id) if @inventory.type_for_params == 'event'

    @latest = Inventory.latest_completed
  end

  def new
    authorize @inventory = Inventory.new
    # What kind of inventory to make?
    # Inventories created by Events#update won't hit this action
    case params[:type]
    when 'receiving'
      @inventory.receiving = true
    when 'shipping'
      @inventory.shipping = true
    else # created manually
      @inventory.manual = true
    end
  end

  def create
    @date = inventory_params[:date]

    @matching = Inventory.where(date: Date.parse(@date)).latest

    if inventory_params[:receiving] == 'true'
      @type = 'receiving'
    elsif inventory_params[:shipping] == 'true'
      @type = 'shipping'
    elsif inventory_params[:manual] == 'true'
      @type = 'manual'
    else
      @type = 'unknown'
    end

    if @matching.present? && @matching.type_for_params == @type
      # No two inventories of the same type on the same day
      flash[:warning] = "A #{@type} inventory already exists for #{inventory_params[:date]}, please use that one."
      return redirect_to inventories_path
    end

    authorize @inventory = Inventory.create(inventory_params)
    @inventory.save

    CountCreate.new(@inventory)

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(': ')
    else
      flash[:success] = 'The inventory has been created.'
      redirect_to inventories_path
    end
  end

  def edit
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| [c.sort_by_user, - c.name] }
    @uncounted = @inventory.counts.where(user_id: nil).count

    @tech_ids = []
    @inventory.counts.each do |c|
      @tech_ids << c.item.technologies.map(&:id)
    end

    @tech_ids.flatten!
    @tech_ids.uniq!

    @techs = Technology.find(@tech_ids)

    if params[:unlock] == 'true'
      @inventory.completed_at = nil
      @inventory.save
    end

    case @inventory.type_for_params
    when 'receiving'
      @btn_text = 'Receive'
    when 'shipping'
      @btn_text = 'Ship'
    when 'manual'
      @btn_text = 'Count'
    else
      @btn_text = 'Adjust'
    end
  end

  def update
    authorize @inventory = Inventory.find(params[:id])

    @inventory.update(inventory_params)
    Extrapolate.new(@inventory)

    InventoryMailer.delay.notify(@inventory, current_user) if @inventory.type_for_params == 'manual' || @inventory.has_items_below_minimum?

    redirect_to inventories_path
  end

  def order
    authorize @inventory = Inventory.latest_completed

    @selected_owner_acronym = params[:owner] if params[:owner].present?
    @selected_owner = @selected_owner_acronym ? find_owner_from_acronym(@selected_owner_acronym) : nil
    @technologies = @selected_owner ? Technology.status_worthy.where(owner: @selected_owner) : Technology.status_worthy

    @owners_select = Technology.status_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
    @technologies_select = @technologies.map { |t| [t.name, t.id] }

    @selected_tech_id = @technologies.find(params[:tech]).id if params[:tech].present?
    @selected_tech = @technologies.find(@selected_tech_id) if @selected_tech_id

    if @selected_tech_id
      @low_counts = @inventory.counts.select { |c| c.reorder? && c.technologies.map(&:id).include?(@selected_tech_id) }
    elsif @selected_owner_acronym
      @low_counts = @inventory.counts.select { |c| c.reorder? && c.owner.include?(@selected_owner_acronym) }
    else
      @low_counts = @inventory.counts.select(&:reorder?)
    end

    # @low_counts.is_a?(ActiveRecord::Relation) == false
    @order_counts = Count.where(id: @low_counts.map(&:id))
    @suppliers = @order_counts.map(&:supplier).uniq

    # Counts without a supplier
    @no_supplier = @order_counts.select { |c| c.supplier.nil? }

    @total_cost = @low_counts.map { |c| c.item.reorder_total_cost }.sum
  end

  def order_all
    authorize @inventory = Inventory.latest_completed

    @selected_owner_acronym = params[:owner] if params[:owner].present?
    @selected_owner = @selected_owner_acronym ? find_owner_from_acronym(@selected_owner_acronym) : nil
    @technologies = @selected_owner ? Technology.status_worthy.where(owner: @selected_owner) : Technology.status_worthy

    @owners_select = Technology.status_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
    @technologies_select = @technologies.map { |t| [t.name, t.id] }

    @selected_tech_id = @technologies.find(params[:tech]).id if params[:tech].present?
    @selected_tech = @technologies.find(@selected_tech_id) if @selected_tech_id

    if @selected_tech_id
      @counts = @inventory.counts.not_components.select { |c| c.technologies.map(&:id).include?(@selected_tech_id) }
    elsif @selected_owner_acronym
      @counts = @inventory.counts.not_components.select { |c| c.owner.include?(@selected_owner_acronym) }
    else
      @counts = @inventory.counts.not_components
    end

    @suppliers = @counts.map(&:supplier).uniq

    # Counts without a supplier
    @no_supplier = @counts.select { |c| c.supplier.nil? }

    @total_cost = @counts.map { |c| c.item.reorder_total_cost }.sum
  end

  def status
    authorize @inventory = Inventory.latest_completed

    @techs = Technology.status_worthy

    @finder = 'status'
  end

  def paper
    @print_navbar = true
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| [c.group_by_tech, c.name] }
  end

  def destroy
    authorize @inventory = Inventory.find(params[:id])
  end

  def financials
    authorize @latest = Inventory.latest_completed
    @counts = @latest.counts

    @scope = params[:group]

    case @scope
    when 'owner'
      @owners = Technology.order(:owner).finance_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
    when 'technology'
      @technologies = Technology.order(:owner, :name).finance_worthy
    else # un-grouped
      @built_counts = @counts.joins(:component).where('components.completed_tech = ?', true)
      @val_unbuilt = @counts.where(component_id: nil).map(&:avail_value).sum
      @val_built = @built_counts.map(&:avail_value).sum
      @val_ttl = @val_built + @val_unbuilt
    end
  end

  private

  def inventory_params
    params.require(:inventory).permit :date, :reported, :receiving, :shipping, :manual, :deleted_at, :event_id, :completed_at,
                                      counts_attributes: [:id, :user_id, :inventory_id, :component_id, :part_id, :material_id, :loose_count, :unopened_boxes_count, :deleted_at]
  end

  def find_owner_from_acronym(owner)
    Technology.status_worthy.map { |t| [t.owner_acronym, t.owner] }.uniq.to_h[owner]
  end
end
