class CountsController < ApplicationController

  def index
    @inventory = Inventory.find(params[:inventory_id])

    @counts = @inventory.counts
  end

  def create
    @count = Count.find_or_initialize_by(params[:id])
    # should also check item ids so no duplicate counts for the same inventory
  end

  # def new
  #   @inventory = Inventory.find(params[:inventory_id])
  #   @count = @inventory.count.new
  # end

  def edit
    @count = Count.find(params[:id])
    @inventory = @count.inventory
  end

  def show
    @count = Count.find(params[:id])
    @inventory = @count.inventory
  end

  def update
    @count = Count.find(params[:id])
    @inventory = @count.inventory

    if @count.update_attributes(count_params)
      flash[:success] = "Item count submitted"
      redirect_to edit_inventory_path(@inventory)
    else
      render 'edit'
    end


  end

  def destroy
    @count = Count.find(params[:id])
    @inventory = @count.inventory
  end

  private

  def count_params
    params.require(:count).permit :user_id, :components_id, :parts_id, :materials_id,
                                  :loose_count, :unopened_boxes_count, :deleted_at
  end

end
