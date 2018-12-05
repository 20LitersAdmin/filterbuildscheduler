# frozen_string_literal: true

class InventoriesController < ApplicationController

  def index
    @latest = Inventory.latest
    @inventories = Inventory.former

    authorize @latest
  end

  def show
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by {|c| - c.name }

    if @inventory.type_for_params == "manual"
      # show only what's ready for shipping
      @primary_components = Component.where(completed_tech: true).map { |c| c.id }
      @primary_component_counts = @inventory.counts.where(component_id: @primary_components).sort_by {|c| - c.name }
    else
      # show only what's changed
      @diff_counts = @inventory.counts.where.not(user_id: nil).sort_by {|c| - c.name }
    end

    if @inventory.type_for_params == "event"
      @event = Event.find(@inventory.event_id)
    end

    @latest = Inventory.latest
  end

  def new
    authorize @inventory = Inventory.new()
    # What kind of inventory to make?
    # Inventories created by Events#update won't hit this action
    case params[:type]
    when "receiving"
      @inventory.receiving = true
    when "shipping"
      @inventory.shipping = true
    else # created manually
      @inventory.manual = true
    end
  end

  def create
    @date = inventory_params[:date]

    @matching = Inventory.where(date: Date.parse(@date)).last

    if inventory_params[:receiving] == "true"
      @type = "receiving"
    elsif inventory_params[:shipping] == "true"
      @type = "shipping"
    elsif inventory_params[:manual] == "true"
      @type = "manual"
    else
      @type = "unknown"
    end

    if @matching&.type_for_params == @type
      # No two inventories of the same type on the same day
      flash[:warning] = "A #{@type} inventory already exists for #{inventory_params[:date]}, please use that one."
      return redirect_to inventories_path
    end

    authorize @inventory = Inventory.create(inventory_params)
    @inventory.save

    CountCreate.new(@inventory)

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(": ")
    else
      flash[:success] = "The inventory has been created."
      redirect_to inventories_path
    end
  end

  def edit
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| [c.sort_by_user, - c.name] }
    @uncounted = @inventory.counts.where(user_id: nil).count

    @tech_ids = []
    @inventory.counts.each do |c|
      @tech_ids << c.item.technologies.map { |t| t.id }
    end

    @tech_ids.flatten!
    @tech_ids.uniq!

    @techs = Technology.find(@tech_ids)

    if params[:unlock] == "true"
      @inventory.completed_at = nil
      @inventory.save
    end

    case @inventory.type_for_params
    when "receiving"
      @btn_text = "Receive"
    when "shipping"
      @btn_text = "Ship"
    when "manual"
      @btn_text = "Count"
    else
      @btn_text = "Adjust"
    end

  end

  def update
    authorize @inventory = Inventory.find(params[:id])

    @inventory.update(inventory_params)
    Extrapolate.new(@inventory)

    # FUTURE FEATURE
    # When parts.where(made_from_materials: true) is increased from previous, related materials should decrease fractionally
    # Divide.new(@inventory, @loose, @box)


    if @inventory.type_for_params == "manual" || @inventory.has_items_below_minimum?
      InventoryMailer.delay.notify(@inventory, current_user)
    end
    redirect_to inventories_path
  end

  def order
    authorize @inventory = Inventory.latest
    @low_counts = @inventory.counts.select{ |count| count.reorder? }

    @order_counts = Count.where(id: @low_counts.map { |c| c.id })

    @suppliers = @order_counts.map { |c| c.supplier }.uniq

    # Counts without a supplier
    @no_supplier = @order_counts.select{ |c| c.supplier == nil }

    @low_counts = @inventory.counts.select{ |count| count.reorder? }
    @total_cost = @low_counts.map { |c| c.item.reorder_total_cost }.sum

    @latest = Inventory.latest
  end

  def status
    authorize @inventory = Inventory.latest

    @techs = Technology.status_worthy

    @finder = "status"
  end

  def paper
    @print_navbar = true
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| [c.group_by_tech, c.name] }
  end

  def labels
    # print labels for all Parts, Materials and Components in the system
    @print_navbar = true
    authorize @inventory = Inventory.latest
    @counts = @inventory.counts.sort_by { |c| [c.group_by_tech, c.name] }
  end

  def destroy
    authorize @inventory = Inventory.find(params[:id])
  end

  private

  def inventory_params
    params.require(:inventory).permit :date, :reported, :receiving, :shipping, :manual, :deleted_at, :event_id, :completed_at,
                                      counts_attributes: [:id, :user_id, :inventory_id, :component_id, :part_id, :material_id, :loose_count, :unopened_boxes_count, :deleted_at]
  end
end
