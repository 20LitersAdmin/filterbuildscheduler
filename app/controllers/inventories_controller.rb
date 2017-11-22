class InventoriesController < ApplicationController

  def index
    @latest = Inventory.latest
    @former = Inventory.former
  end

  def create
    @inventory = Inventory.find_or_initialize_by(params[:id])
    # should also check on date so you can't duplicate an inventory on the same day.
  end

  def new
    @inventory = Inventory.new
  end

  def edit
    @inventory = Inventory.find(params[:id])
  end

  def show
    @inventory = Inventory.find(params[:id])
  end

  def update
    @inventory = Inventory.find(params[:id])
  end

  def destroy
    @inventory = Inventory.find(params[:id])
  end

  private

  def inventory_params
    params.require(:inventory).permit :date, :reported, :receiving, :shipping, :deleted_at, :event_id,
        counts_attributes: [:id, :user_id, :components_id, :parts_id, :materials_id, :loose_count, :unopened_boxes_count, :deleted_at]
  end
end
