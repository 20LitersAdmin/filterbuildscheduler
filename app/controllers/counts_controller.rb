class CountsController < ApplicationController

  # def index
  #   @inventory = Inventory.find(params[:inventory_id])
  #   @counts = @inventory.counts
  # end

  # def create
  #   @count = Count.find_or_initialize_by(params[:id])
  #   # should also check item ids so no duplicate counts for the same inventory
  # end

  # def new
  #   @inventory = Inventory.find(params[:inventory_id])
  #   @count = @inventory.count.new
  # end

  def edit
    @count = Count.find(params[:id])
    @inventory = @count.inventory

    if @count.user_id.present?
      # Doesn't show me only received for type: received, but will work for manual
      @loose_val = @count.loose_count
      @box_val = @count.unopened_boxes_count
    else

      @loose_val = 0
      @box_val = 0
    end
  end

  # def show
  #   @count = Count.find(params[:id])
  #   @inventory = @count.inventory
  # end

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

    if @inventory.receiving
      modified_params[:loose_count] = @count.loose_count + count_params[:loose_count].to_i
      modified_params[:unopened_boxes_count] = @count.unopened_boxes_count + count_params[:unopened_boxes_count].to_i
    end

    if @inventory.shipping
      modified_params[:loose_count] = @count.loose_count - count_params[:loose_count].to_i
      modified_params[:unopened_boxes_count] = @count.unopened_boxes_count - count_params[:unopened_boxes_count].to_i

      if modified_params[:loose_count].to_i < 0 || modified_params[:unopened_boxes_count].to_i < 0
        # only one type of inventory can have negative numbers.
        @count.errors.add(:loose_count, "Can't submit negative numbers for this type of inventory.")
      end
    end

    @count.update_attributes(modified_params)

    if @count.errors.any?
      flash[:danger] = @registration.errors.messages.map { |k,v| v }.join(', ')
    else
      flash[:success] = "Count submitted"
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
