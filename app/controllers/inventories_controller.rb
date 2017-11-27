class InventoriesController < ApplicationController

  def index
    @latest = Inventory.latest
    @inventories = Inventory.former
  end

  def create
    @date = inventory_params[:date]
    @latest = Inventory.latest
    if @latest.present?
      @latest_id = @latest.id
    else
      @latest_id = nil
    end

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
      flash[:warning] = "An #{@type} inventory already exists for #{inventory_params[:date]}, please use that one."
      return redirect_to inventories_path
    end

    @inventory = Inventory.create(inventory_params)
    @inventory.save

    ### Make all the counts
    @part_ids = Part.all.map { |o| o.id }
    @part_ids.each do |p|
      old_part_count = Count.where(inventory_id: @latest_id).where(part_id: p).last
      if old_part_count.present?
        new_part_count = old_part_count.dup
        new_part_count.inventory_id = @inventory.id
        new_part_count.user_id = nil
        new_part_count.save
      else
        Count.create(inventory_id: @inventory.id, part_id: p)
      end
    end

    @material_ids = Material.all.map { |o| o.id }
    @material_ids.each do |m|
      old_material_count = Count.where(inventory_id: @latest_id).where(material_id: m).last
      if old_material_count.present?
        new_material_count = old_material_count.dup
        new_material_count.inventory_id = @inventory.id
        new_material_count.user_id = nil
        new_material_count.save
      else
        Count.create(inventory_id: @inventory.id, material_id: m)
      end
    end

    @component_ids = Component.all.map { |o| o.id }
    @component_ids.each do |c|
      old_component_count = Count.where(inventory_id: @latest_id).where(component_id: c).last
      if old_component_count.present?
        new_component_count = old_component_count.dup
        new_component_count.inventory_id = @inventory.id
        new_component_count.user_id = nil
        new_component_count.save
      else
        Count.create(inventory_id: @inventory.id, component_id: c)
      end
    end

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(": ")
    else
      flash[:success] = "The inventory has been created."
      redirect_to inventories_path
    end
  end

  def new
    @inventory = Inventory.new()
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

  def edit
    @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| [c.sort_by_user, c.tech_names, - c.name] }
    @uncounted = @inventory.counts.where(user_id: nil).count
  end

  def show
    @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by {|c| - c.name }
  end

  def update
    @inventory = Inventory.find(params[:id])

    @inventory.update(inventory_params)

    if inventory_params[:completed_at].present?
      # Extrapolate components through Intelligence::extrapolate(@inventory)
      # Mail out inventory upon update.
    end

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(": ")
    else
      flash[:success] = "Inventory updated"
    end

    redirect_to inventories_path
  end

  def destroy
    @inventory = Inventory.find(params[:id])
  end

  private

  def inventory_params
    params.require(:inventory).permit :date, :reported, :receiving, :shipping, :manual, :deleted_at, :event_id,
                                      counts_attributes: [:id, :user_id, :inventory_id, :component_id, :part_id, :material_id, :loose_count, :unopened_boxes_count, :deleted_at]
  end
end
