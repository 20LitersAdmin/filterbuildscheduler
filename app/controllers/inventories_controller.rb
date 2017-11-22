class InventoriesController < ApplicationController

  def index
    @latest = Inventory.latest
    @inventories = Inventory.former
  end

  def create
    @date = inventory_params[:date]
    if Inventory.all.present? # amoeba_dup
      if Inventory.latest.date == @date
        flash[:warning] = "An inventory exists for #{inventory_params[:date]}, please use that one."
        return redirect_to inventories_path
      else #new date = new inventory
        # copy all the previous counts over
        @latest = Inventory.latest
        @inventory = @latests.amoeba_dup

        # set the new inventory type && date
        @inventory.date = inventory_params[:date]
        @inventory.receiving = inventory_params[:receiving]
        @inventory.shipping = inventory_params[:shipping]
        @inventory.manual = inventory_params[:manual]
        @inventory.event_id = inventory_params[:event_id]

        @inventory.save
      end
    else # very first inventory
      @inventory = Inventory.create(inventory_params)
    end

    ### Make all the counts, unless they already exist from the amoeba_dup
    @parts_ids = Part.all.map { |o| o.id }
    @parts_ids.each do |p|
      Count.where(inventory_id: @inventory.id).where(parts_id: p).first_or_create(user_id: current_user.id)
    end
    @materials_ids = Material.all.map { |o| o.id }
    @materials_ids.each do |m|
      Count.where(inventory_id: @inventory.id).where(materials_id: m).first_or_create(user_id: current_user.id)
    end
    @components_ids = Component.all.map { |o| o.id }
    @components_ids.each do |c|
      Count.where(inventory_id: @inventory.id).where(components_id: c).first_or_create(user_id: current_user.id)
    end

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(": ")
    else
      flash[:success] = "The inventory has been created."
    end

    redirect_to inventories_path
  end

  def new
    @inventory = Inventory.new()
    # What kind of inventory to make?
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
  end

  def show
    @inventory = Inventory.find(params[:id])
  end

  def update
    @inventory = Inventory.find(params[:id])

    # Mail out inventory upon update. Maybe use @inventory.complete? field?
  end

  def destroy
    @inventory = Inventory.find(params[:id])
  end

  private

  def inventory_params
    params.require(:inventory).permit :date, :reported, :receiving, :shipping, :manual, :deleted_at, :event_id
  end
end
