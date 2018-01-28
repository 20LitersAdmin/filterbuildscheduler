class CountsController < ApplicationController

  def edit
    authorize @count = Count.find(params[:id])
    @inventory = @count.inventory

    case @inventory.type_for_params
    when "receiving"
      @context = "Add to inventory: Use positive numbers"
      @expected_msg = "Current:"
    when "shipping"
      @context = "Remove from inventory: Use negative numbers"
      @expected_msg = "Current:"
    when "manual"
      @context = "Count inventory: Use positive numbers or 0"
      @expected_msg = "Expected to be:"
    when "event"
      @context = "Adjust inventory: Use positive or negative numbers"
      @expected_msg = "Current:"
    end

    # counts with user_ids have been saved at least once. counts marked as partials still need work
    if @count.user_id.present? || @count.partial_box || @count.partial_loose 
      if @inventory.type_for_params == "manual"
        @loose_val = @count.loose_count
        @box_val = @count.unopened_boxes_count
      else # "shipping" || "receiving" || "event"
        @loose_val = @count.diff_from_previous("loose")
        @box_val = @count.diff_from_previous("box")
      end
    elsif @inventory.type_for_params == "event" # if it's related to an event, show the diff since the last inventory
      @loose_val = @count.diff_from_previous("loose")
        @box_val = @count.diff_from_previous("box")
    else #if a count hasn't been submitted, show 0
      @loose_val = 0
      @box_val = 0
    end

    if @count.partial_box
      @loose_val = ''
    end

    if @count.partial_loose
      @box_val = ''
    end
  end

  def update
    authorize @count = Count.find(params[:id])
    @inventory = @count.inventory

    case @inventory.type_for_params
    when "receiving"
      @context = "Add to inventory: Use positive numbers"
      @expected_msg = "Current:"
    when "shipping"
      @context = "Remove from inventory: Use negative numbers"
      @expected_msg = "Current:"
    when "manual"
      @context = "Count inventory: Use positive numbers or 0"
      @expected_msg = "Expected to be:"
    when "event"
      @context = "Adjust inventory: Use positive or negative numbers"
      @expected_msg = "Current:"
    end

    # counts with user_ids have been saved at least once. counts marked as partials still need work
    if @count.user_id.present? || @count.partial_box || @count.partial_loose 
      if @inventory.type_for_params == "manual"
        @loose_val = @count.loose_count
        @box_val = @count.unopened_boxes_count
      else # "shipping" || "receiving" || "event"
        @loose_val = @count.diff_from_previous("loose")
        @box_val = @count.diff_from_previous("box")
      end
    elsif @inventory.type_for_params == "event" # if it's related to an event, show the diff since the last inventory
      @loose_val = @count.diff_from_previous("loose")
        @box_val = @count.diff_from_previous("box")
    else #if a count hasn't been submitted, show 0
      @loose_val = 0
      @box_val = 0
    end

    if @count.partial_box
      @loose_val = ''
    end

    if @count.partial_loose
      @box_val = ''
    end

    modified_params = count_params.dup

    # Partial counts are not complete, thus user_id should be set to nil
    if params[:partial_box].present? # "Partial Count: Boxes" button was pushed
      modified_params.delete(:user_id)
      modified_params.delete(:loose_count)
      @count.partial_box = true
      @count.partial_loose = false
    end

    if params[:partial_loose].present? # "Partial Count: Loose" button was pushed
      modified_params.delete(:user_id)
      modified_params.delete(:unopened_boxes_count)
      @count.partial_box = false
      @count.partial_loose = true
    end

    if params[:commit].present? # "Submit" button was pushed
      @count.partial_box = false
      @count.partial_loose = false
    end

    # Ignore null field values, default to previous values
    if count_params[:loose_count] == ""
      modified_params.delete(:loose_count)
    end
    if count_params[:unopened_boxes_count] == ""
      modified_params.delete(:unopened_boxes_count)
    end

    # Adjust the previous count unless it's a manual inventory
    if @inventory.receiving || @inventory.shipping || @inventory.type_for_params == "event"
      if count_params[:user_id].present? # this is being touched by a person
        
        # If the values matches, don't re-submit the value again
        if count_params[:loose_count].to_i == @count.diff_from_previous("loose")
          modified_params.delete(:loose_count)
        else # if the value is different, submit the difference
          modified_params[:loose_count] = @count.loose_count + ( count_params[:loose_count].to_i - @count.diff_from_previous("loose") )
        end

        # If the values matches, don't re-submit the value again
        if count_params[:unopened_boxes_count].to_i == @count.diff_from_previous("box")
          modified_params.delete(:unopened_boxes_count)
        else # if the value is different, submit the difference
          modified_params[:unopened_boxes_count] = @count.unopened_boxes_count + ( count_params[:unopened_boxes_count].to_i - @count.diff_from_previous("box") )
        end
      end # count_params[:user_id].present?
    end # @inventory.receiving || @inventory.shipping || @inventory.type_for_params == "event"

    if @inventory.receiving || @inventory.type_for_params == "manual"
      # only shipping and event inventories can have negative numbers.
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

      if @count.loose_count + count_params[:loose_count].to_i < 0
        @count.errors.add(:loose_count, "You only have #{@count.loose_count} to ship")
      end
      if @count.unopened_boxes_count + count_params[:unopened_boxes_count].to_i < 0
        @count.errors.add(:unopened_boxes_count, "You have #{@count.unopened_boxes_count} to ship")
      end
    end

    if @count.errors.any?
      render 'edit'
    else
      flash[:success] = "Count submitted"
      @count.update_attributes(modified_params)
      redirect_to edit_inventory_path(@inventory)
    end


  end

  def destroy
    authorize @count = Count.find(params[:id])
    @inventory = @count.inventory
  end

  private

  def count_params
    params.require(:count).permit :user_id, :components_id, :parts_id, :materials_id,
                                  :loose_count, :unopened_boxes_count, :deleted_at
  end

end
