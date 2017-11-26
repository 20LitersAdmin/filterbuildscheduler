class InventoriesController < ApplicationController

  def index
    @latest = Inventory.latest
    @inventories = Inventory.former
  end

  def create
    @date = inventory_params[:date]
    if Inventory.all.present? # amoeba_dup
      if Inventory.latest.date == Date.parse(@date)
        flash[:warning] = "An inventory already exists for #{inventory_params[:date]}, please use that one."
        return redirect_to inventories_path
      else #new date = new inventory
        # copy all the previous counts over
        @latest = Inventory.latest
        @inventory = @latest.amoeba_dup

        # set the new inventory type && date
        @inventory.date = inventory_params[:date]
        @inventory.receiving = inventory_params[:receiving]
        @inventory.shipping = inventory_params[:shipping]
        @inventory.manual = inventory_params[:manual]
        @inventory.event_id = inventory_params[:event_id]

        @inventory.save

        ### Clear out all the user_ids from the original, this is used to keep track of which fields get updated later.
        @inventory.counts.each do |c|
          c.user_id = nil
          c.save
        end
      end
    else # very first inventory
      @inventory = Inventory.create(inventory_params)
    end

    ### Make all the counts, unless they already exist from the amoeba_dup
    @part_ids = Part.all.map { |o| o.id }
    @part_ids.each do |p|
      Count.where(inventory_id: @inventory.id).where(part_id: p).first_or_create
    end
    @material_ids = Material.all.map { |o| o.id }
    @material_ids.each do |m|
      Count.where(inventory_id: @inventory.id).where(material_id: m).first_or_create
    end
    @component_ids = Component.all.map { |o| o.id }
    @component_ids.each do |c|
      Count.where(inventory_id: @inventory.id).where(component_id: c).first_or_create
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
