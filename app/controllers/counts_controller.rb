class CountsController < ApplicationController

  def edit
    @count = Count.find(params[:id])
    @inventory = @count.inventory

    case @inventory.type_for_params
    when "receiving"
      @context = "Add to inventory: Use positive numbers"
    when "shipping"
      @context = "Remove from inventory: Use negative numbers"
    when "manual"
      @context = "Count inventory: Use positive numbers or 0"
    end

    if @count.user_id.present? #after a record is submitted, show the submitted value
      if @inventory.type_for_params == "manual"
        @loose_val = @count.loose_count
        @box_val = @count.unopened_boxes_count
      else # "shipping" || "receiving"
        # This is causing re-submission of the same amount
        @loose_val = @count.diff_from_previous("loose")
        @box_val = @count.diff_from_previous("box")
      end
    else #if a count hasn't been submitted, show 0
      @loose_val = 0
      @box_val = 0
    end
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

    # Adjust the previous count unless it's a manual inventory
    if @inventory.receiving || @inventory.shipping
      # if the count has already been submitted && the val matches, don't re-submit the value again
      if count_params[:user_id].present? && modified_params[:loose_count].to_i == @count.diff_from_previous("loose")
        modified_params.delete(:loose_count)
      else
        modified_params[:loose_count] = @count.loose_count + count_params[:loose_count].to_i
      end
      if count_params[:user_id].present? && modified_params[:unopened_boxes_count].to_i == @count.diff_from_previous("box")
        modified_params.delete(:unopened_boxes_count)
      else
        modified_params[:unopened_boxes_count] = @count.unopened_boxes_count + count_params[:unopened_boxes_count].to_i
      end
    end

    if !@inventory.shipping
      # only one type of inventory can have negative numbers.
      if count_params[:loose_count].to_i < 0
        @count.errors.add(:loose_count, "Loose Count can't be negative for this type of inventory.")
      end
      if count_params[:unopened_boxes_count].to_i < 0
        @count.errors.add(:unopened_boxes_count, "Box Count can't be negative for this type of inventory.")
      end
    end

    if @inventory.shipping
      # for logical safety, shipping inventory #s must be negative
      if count_params[:loose_count].to_i > 0
        @count.errors.add(:loose_count, "Loose Count can't be positive for this type of inventory.")
      end
      if count_params[:unopened_boxes_count].to_i > 0
        @count.errors.add(:unopened_boxes_count, "Box Count can't be positive for this type of inventory.")
      end
    end

    binding.pry

    if @count.errors.any?
      render 'edit'
    else
      flash[:success] = "Count submitted"
      @count.update_attributes(modified_params)
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
