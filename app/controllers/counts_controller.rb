# frozen_string_literal: true

class CountsController < ApplicationController
  before_action :set_count, only: %i[edit show update destroy]
  before_action :set_inventory, only: %i[edit show update destroy]

  def edit
    respond_to do |format|
      format.html
      format.js { render 'edit', layout: false }
    end
  end

  def show
    redirect_to edit_inventory_count_path(@inventory, @count)
  end

  def update
    button =
      if params[:commit].present?
        'submit'
      else
        params[:partial_box].present? ? 'box' : 'loose'
      end

    @count.user_id = current_user.id

    # CountUpdate: validates for errors, saves if no errors
    # for partial submissions ("loose count" / "box count"), the other value is set to 0

    CountUpdate.new(@count, count_params, button)

    if @count.errors.any?
      render 'edit'
    else
      CountsChannel.broadcast_to(
        @inventory,
        {
          count_id: @count.id,
          html_slug: render_to_string(partial: 'counts/count', collection: @inventory.counts.sort_by { |c| [c.sort_by_status, - c.item.name] }),
          uncounted: "#{view_context.pluralize(@inventory.counts.uncounted.size, 'item')} uncounted."
        }
      )

      respond_to do |format|
        format.html do
          flash[:success] = 'Count submitted'
          redirect_to edit_inventory_path(@inventory)
        end

        format.js { render 'update', layout: false }
      end
    end
  end

  def destroy; end

  private

  def count_params
    params.require(:count).permit :components_id,
                                  :parts_id,
                                  :materials_id,
                                  :loose_count,
                                  :unopened_boxes_count
  end

  def set_count
    authorize @count ||= Count.find(params[:id])
  end

  def set_inventory
    @inventory = Inventory.find(params[:inventory_id])
  end
end
