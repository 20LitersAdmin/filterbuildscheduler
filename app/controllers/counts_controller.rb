# frozen_string_literal: true

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
      @expected_msg = "Previous:"
    when "event"
      @context = "Adjust inventory: Use positive or negative numbers"
      @expected_msg = "Current:"
    end

    # Set form values
    @loose_val = ''
    @box_val = ''

    if @count.partial_box?
      @box_val = @count.unopened_boxes_count
    end

    if @count.partial_loose?
      @loose_val = @count.loose_count
    end

    if @count.user_id.present?
      @loose_val = @count.loose_count
      @box_val = @count.unopened_boxes_count
    end
  end

  def update
    authorize @count = Count.find(params[:id])
    @inventory = @count.inventory

    # VALIDATIONS
    if @inventory.receiving? || @inventory.manual?
      # receiving and manual inventories must have positive numbers
      if count_params[:loose_count].to_i < 0
        @count.errors.add(:loose_count, "Loose Count can't be negative for this type of inventory.")
      end
      if count_params[:unopened_boxes_count].to_i < 0
        @count.errors.add(:unopened_boxes_count, "Box Count can't be negative for this type of inventory.")
      end
    end

    if @inventory.shipping?
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
        @count.errors.add(:unopened_boxes_count, "You only have #{@count.unopened_boxes_count} to ship")
      end
    end

    # Partial counts are not complete, thus user_id should be set to nil
    if params[:partial_box].present? # "Partial Count: Boxes" button was pushed
      @count.partial_box = true
      @count.partial_loose = false
    end

    if params[:partial_loose].present? # "Partial Count: Loose" button was pushed
      @count.partial_box = false
      @count.partial_loose = true
    end

    if params[:commit].present? # "Submit" button was pushed
      @count.partial_box = false
      @count.partial_loose = false
      @count.user_id = current_user.id
    end

    # and finally, set the values
    if @inventory.manual?
      if count_params[:loose_count].present?
        @count.loose_count = count_params[:loose_count].to_i
      end
      if count_params[:unopened_boxes_count].present?
        @count.unopened_boxes_count = count_params[:unopened_boxes_count].to_i
      end
    else # @inventory.receiving || @inventory.shipping # @inventory.event_id.present?
      if count_params[:loose_count].present?
        @count.loose_count = @count.previous_loose + count_params[:loose_count].to_i
      end
      if count_params[:unopened_boxes_count].present?
        @count.unopened_boxes_count = @count.previous_box + count_params[:unopened_boxes_count].to_i
      end
    end

    if @count.errors.any?
      case @inventory.type_for_params
      when "receiving"
        @context = "Add to inventory: Use positive numbers"
        @expected_msg = "Current:"
      when "shipping"
        @context = "Remove from inventory: Use negative numbers"
        @expected_msg = "Current:"
      when "manual"
        @context = "Count inventory: Use positive numbers or 0"
        @expected_msg = "Previous:"
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
      else #if a count hasn't been submitted, show blanks
        @loose_val = ''
        @box_val = ''
      end
      render 'edit'
    else
      flash[:success] = "Count submitted"
      @count.save
      redirect_to edit_inventory_path(@inventory)
    end
  end

  def labels
    # Choose which label to print
    @counts = Inventory.latest.counts.sort_by { |c| [c.group_by_tech, c.item.uid] }
  end

  def label
    # print full sheet of lables for this one item
    @count = Count.find(params[:id])
  end


  def destroy
    authorize @count = Count.find(params[:id])
    @inventory = @count.inventory
  end

  private

  def count_params
    params.require(:count).permit :components_id, :parts_id, :materials_id,
                                  :loose_count, :unopened_boxes_count, :deleted_at
  end

end
