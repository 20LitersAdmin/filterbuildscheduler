# frozen_string_literal: true

class CountsController
  class CountUpdate
    def initialize(count, count_params, button)
      @count = count
      @item = @count.item
      @inventory = @count.inventory
      @count_params = count_params
      @button = button

      # set values before returning due to errors so the returned record will have the new values, even though they are in error. User can correct on 'edit' form
      if @button == 'submit'
        set_values
      else
        set_partials
      end

      @inventory.shipping? ? validate_shipping : validate_not_shipping

      return if @count.errors.any?

      @count.save
    end

    def validate_shipping
      # for logical safety, shipping values must be negative
      @count.errors.add(:loose_count, 'Must use negative numbers when shipping inventory.') if @count_params[:loose_count].to_i.positive?

      @count.errors.add(:unopened_boxes_count, 'Must use negative numbers when shipping inventory.') if @count_params[:unopened_boxes_count].to_i.positive?

      # can't ship more than you have
      @count.errors.add(:loose_count, "You only have #{@item.loose_count} to ship") if (@item.loose_count + @count_params[:loose_count].to_i).negative?

      @count.errors.add(:unopened_boxes_count, "You only have #{@item.box_count} to ship") if (@item.box_count + @count_params[:unopened_boxes_count].to_i).negative?
    end

    def validate_not_shipping
      @count.errors.add(:loose_count, 'Must use positive numbers for this type of inventory.') if @count_params[:loose_count].to_i.negative?

      @count.errors.add(:unopened_boxes_count, 'Must use positive numbers for this type of inventory.') if @count_params[:unopened_boxes_count].to_i.negative?
    end

    def set_partials
      # If button != 'submit'

      @count.partial_box = false
      @count.partial_loose = false

      @count.user_id = nil

      @count.loose_count = 0
      @count.unopened_boxes_count = 0

      case @button
      when 'box'
        @count.partial_box = true
        @count.unopened_boxes_count = @count_params[:unopened_boxes_count].to_i
      when 'loose'
        @count.partial_loose = true
        @count.loose_count = @count_params[:loose_count].to_i
      end
    end

    def set_values
      # If button == 'submit'

      @count.partial_box = false
      @count.partial_loose = false

      # NOTE: for shipping inventories, these will be negative
      # coerce nils to 0 if necessary
      @count.loose_count = @count_params[:loose_count].to_i
      @count.unopened_boxes_count = @count_params[:unopened_boxes_count].to_i
    end
  end
end
