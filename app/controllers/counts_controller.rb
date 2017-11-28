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

    modified_params = count_params.dup

    # Partial counts are not complete, thus user_id should be set to nil
    if params[:partial].present?
      modified_params[:user_id] = ""
    end

    # Ignore null field values, default to previous values
    if count_params[:loose_count] == ""
      modified_params.delete(:loose_count)
    end
    if count_params[:unopened_boxes_count] == ""
      modified_params.delete(:unopened_boxes_count)
    end

    @count.update_attributes(modified_params)

    if @inventory.shipping == false && (@count.loose_count < 0 || @count.unopened_boxes_count < 0)
      # only one type of inventory can have negative numbers.
      #flash[:danger] = "Can't submit negative numbers for this type of inventory."
      @count.errors.add(:loose_count, "Can't submit negative numbers for this type of inventory.")
      #return redirect_to edit_inventory_count_path(@inventory, @count)
    end

    if @count.errors.any?
      flash[:danger] = @registration.errors.messages.map { |k,v| v }.join(', ')
    else
      flash[:success] = "Item count submitted"
      redirect_to edit_inventory_path(@inventory)
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
