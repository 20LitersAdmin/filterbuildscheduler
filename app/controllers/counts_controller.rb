# frozen_string_literal: true

class CountsController < ApplicationController
  before_action :set_count, only: %i[edit show update destroy]
  before_action :set_inventory, only: %i[edit show update destroy]

  def edit
    # Set form values
    if @inventory.manual?
      if @count.user_id.present? || @count.partial_box? || @count.partial_loose?
        @loose_val = @count.loose_count
        @box_val = @count.unopened_boxes_count
      end
    else
      @loose_val = @count.diff_from_previous('loose') unless @count.diff_from_previous('loose').zero?
      @box_val = @count.diff_from_previous('box') unless @count.diff_from_previous('box').zero?
    end

    respond_to do |format|
      format.html
      format.js { render 'edit.js.erb' }
    end
  end

  def show
    redirect_to edit_inventory_count_path(@inventory, @count)
  end

  def update
    # VALIDATIONS
    if @inventory.manual? || @inventory.receiving?
      # receiving and manual inventories must have positive numbers
      @count.errors.add(:loose_count, 'Must use positive numbers for this type of inventory.') if count_params[:loose_count].to_i.negative?
      @count.errors.add(:unopened_boxes_count, 'Must use positive numbers for this type of inventory.') if count_params[:unopened_boxes_count].to_i.negative?
    end

    if @inventory.shipping?
      # for logical safety, shipping inventory #s must be negative
      @count.errors.add(:loose_count, 'Must use negative numbers when shipping inventory.') if count_params[:loose_count].to_i.positive?
      @count.errors.add(:unopened_boxes_count, 'Must use negative numbers when shipping inventory.') if count_params[:unopened_boxes_count].to_i.positive?

      @count.errors.add(:loose_count, "You only have #{@count.previous_loose} to ship") if (@count.previous_loose + count_params[:loose_count].to_i).negative?
      @count.errors.add(:unopened_boxes_count, "You only have #{@count.previous_box} to ship") if (@count.previous_box + count_params[:unopened_boxes_count].to_i).negative?
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
    end

    if @count.errors.any?
      # Set vars for 'edit' view
      if @inventory.manual?
        if @count.user_id.present? || @count.partial_box? || @count.partial_loose?
          @loose_val = @count.loose_count
          @box_val = @count.unopened_boxes_count
        end
      else
        @box_val = @count.diff_from_previous('box') unless @count.diff_from_previous('box').zero?
        @loose_val = @count.diff_from_previous('loose') unless @count.diff_from_previous('loose').zero?
      end
      render 'edit'
    else
      # and finally, set the values
      @count.user_id = current_user.id unless params[:partial_loose].present? || params[:partial_box].present?

      if @inventory.manual?
        @count.loose_count = count_params[:loose_count].to_i if count_params[:loose_count].present? && !@count.partial_box
        @count.unopened_boxes_count = count_params[:unopened_boxes_count].to_i if count_params[:unopened_boxes_count].present? && !@count.partial_loose
      else # @inventory.receiving || @inventory.shipping # @inventory.event_id.present?
        @count.loose_count = @count.previous_loose + count_params[:loose_count].to_i if count_params[:loose_count].present? && count_params[:loose_count] != @count.diff_from_previous('loose')
        @count.unopened_boxes_count = @count.previous_box + count_params[:unopened_boxes_count].to_i if count_params[:unopened_boxes_count].present? && count_params[:unopened_boxes_count] != @count.diff_from_previous('box')
      end

      @count.save
      @count.reload

      # render_to_string(partial: 'counts/count', collection: @inventory.counts.sort_by { |c| [c.sort_by_user, - c.name] })

      CountsChannel.broadcast_to(
        @inventory,
        {
          count_id: @count.id,
          html_slug: render_to_string(partial: 'counts/count', collection: @inventory.counts.sort_by { |c| [c.sort_by_user, - c.name] })
        }
      )

      respond_to do |format|
        format.html do
          flash[:success] = 'Count submitted'
          redirect_to edit_inventory_path(@inventory)
        end

        format.js { render 'update.js.erb' }
      end
    end
  end

  def destroy; end

  private

  def count_params
    params.require(:count).permit :components_id, :parts_id, :materials_id,
                                  :loose_count, :unopened_boxes_count, :deleted_at
  end

  def set_count
    authorize @count = Count.find(params[:id])
  end

  def set_inventory
    @inventory = Inventory.find(params[:inventory_id])
  end
end
