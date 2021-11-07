# frozen_string_literal: true

class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[show edit update destroy]

  def index
    # NOTE: After creating an inventory, user is redirected to InventoriesController#index
    # Then @latest is visible and user can edit the inventory.
    @latest = Inventory.latest
    authorize @latest

    @below_minimum = Part.below_minimums.any? || Material.below_minimums.any?

    technologies = Technology.active.list_worthy
    components = Component.active
    parts = Part.active
    materials = Material.active

    @items = [technologies, components, parts, materials].flatten
  end

  def new
    authorize @inventory = Inventory.new
    # What kind of inventory to make?
    # Inventories created by Events#update won't hit this action
    case params[:type]
    when 'receiving'
      @inventory.receiving = true
    when 'shipping'
      @inventory.shipping = true
    else # created manually
      @inventory.manual = true
    end

    @technologies = Technology.list_worthy.order(:owner, :short_name)
  end

  def create
    @date = inventory_params[:date]

    @type =
      if inventory_params[:receiving] == 'true'
        'receiving'
      elsif inventory_params[:shipping] == 'true'
        'shipping'
      elsif inventory_params[:manual] == 'true'
        'manual'
      else
        'unknown'
      end

    authorize @inventory = Inventory.create(inventory_params)
    @inventory.save

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(': ')
    else
      # technologies_param is used to bypass some techs and skip making counts
      CountCreateJob.perform_now(@inventory.reload, technologies_params)
      flash[:success] = 'The inventory has been created.'
      redirect_to edit_inventory_path(@inventory)
    end
  end

  def edit
    # This view is where inventory counting gets performed

    redirect_to inventory_path(@inventory) && return if @inventory.counts.none?

    @counts = @inventory.counts.sort_by { |c| [c.sort_by_status, - c.item.name] }
    @uncounted = "#{view_context.pluralize(@inventory.counts.uncounted.size, 'item')} uncounted."

    @techs = Technology.list_worthy
  end

  def update
    authorize @inventory = Inventory.find(params[:id])

    @inventory.completed_at = Time.now.localtime

    # Inventory#after_update triggers:
    # ProduceableJob
    # CountTransferJob
    @inventory.save

    InventoryMailer.delay.notify(@inventory, current_user) if @inventory.type_for_params == 'manual' || @inventory.has_items_below_minimum?

    flash[:success] = 'Inventory complete! All completed counts have been transferred to their items.'

    redirect_to inventories_path
  end

  def show
    # arrive here via #history, not #index
  end

  def destroy
    # from #show, clicking 'Delete this Inventory Record'
    @inventory.destroy

    flash[:success] = 'Inventory record deleted.'
    redirect_to history_inventories_path
  end

  # def show
  #   authorize @inventory = Inventory.find(params[:id])
  #   @counts = @inventory.counts.sort_by { |c| - c.name }

  #   if @inventory.type_for_params == 'manual'
  #     # show only what's ready for shipping
  #     @primary_components = Component.where(completed_tech: true).map(&:id)
  #     @primary_component_counts = @inventory.counts.where(component_id: @primary_components).sort_by { |c| - c.name }
  #   else
  #     # show only what's changed
  #     @diff_counts = @inventory.counts.where.not(user_id: nil).sort_by { |c| - c.name }
  #   end

  #   @event = Event.find(@inventory.event_id) if @inventory.type_for_params == 'event'

  #   @latest = Inventory.latest_completed
  # end

  # def order
  #   authorize Inventory

  #   @selected_owner_acronym = params[:owner] if params[:owner].present?
  #   @selected_owner = @selected_owner_acronym ? find_owner_from_acronym(@selected_owner_acronym) : nil
  #   @technologies = @selected_owner ? Technology.status_worthy.where(owner: @selected_owner) : Technology.status_worthy

  #   @owners_select = Technology.status_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
  #   @technologies_select = @technologies.map { |t| [t.name, t.id] }

  #   @selected_tech_id = @technologies.where(id: params[:tech])&.first&.id if params[:tech].present?
  #   @selected_tech = @technologies.find(@selected_tech_id) if @selected_tech_id

  #   if @selected_tech_id
  #     parts = Part.orderable.select { |part| part.reorder? && part.all_technologies.map(&:id).include?(@selected_tech_id) }
  #     materials = Material.all.select { |m| m.reorder? && m.all_technologies.map(&:id).include?(@selected_tech_id) }
  #   elsif @selected_owner_acronym
  #     parts = Part.orderable.select { |part| part.reorder? && part.owner.include?(@selected_owner_acronym) }
  #     materials = Material.all.select { |m| m.reorder? && m.owner.include?(@selected_owner_acronym) }
  #   else
  #     parts = Part.orderable.select(&:reorder?)
  #     materials = Material.all.select(&:reorder?)
  #   end

  #   @items = [parts, materials].flatten

  #   @order_counts = @items.count
  #   @suppliers = [parts.map(&:supplier).uniq, materials.map(&:supplier).uniq].flatten.uniq.compact

  #   @items_w_no_supplier = @items.select { |item| item.supplier.nil? }
  # end

  # def order_all
  #   authorize Inventory

  #   @selected_owner_acronym = params[:owner] if params[:owner].present?
  #   @selected_owner = @selected_owner_acronym ? find_owner_from_acronym(@selected_owner_acronym) : nil
  #   @technologies = @selected_owner ? Technology.status_worthy.where(owner: @selected_owner) : Technology.status_worthy

  #   @owners_select = Technology.status_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
  #   @technologies_select = @technologies.map { |t| [t.name, t.id] }

  #   @selected_tech_id = @technologies.find(params[:tech]).id if params[:tech].present?
  #   @selected_tech = @technologies.find(@selected_tech_id) if @selected_tech_id

  #   if @selected_tech_id
  #     parts = Part.orderable.select { |part| part.technologies.map(&:id).include?(@selected_tech_id) }
  #     materials = Material.all.select { |m| m.technologies.map(&:id).include?(@selected_tech_id) }
  #   elsif @selected_owner_acronym
  #     parts = Part.orderable.select { |part| part.owner.include?(@selected_owner_acronym) }
  #     materials = Material.all.select { |m| m.owner.include?(@selected_owner_acronym) }
  #   else
  #     parts = Part.orderable
  #     materials = Material.all
  #   end

  #   @items = [parts, materials].flatten
  #   @suppliers = [parts.map(&:supplier).uniq, materials.map(&:supplier).uniq].flatten.uniq.compact

  #   @items_w_no_supplier = @items.select { |item| item.supplier.nil? }
  # end

  # def status
  #   authorize @inventory = Inventory.latest_completed

  #   @techs = Technology.status_worthy

  #   @finder = 'status'
  # end

  def paper
    @print_navbar = true

    technologies = Technology.active.list_worthy
    components = Component.active
    parts = Part.active
    materials = Material.active

    @items = [technologies, components, parts, materials].flatten
  end

  def history
    # TODO: have "undo" button, maybe just for most recent? Or just for @inventory.event_based?
    # Does "undo" call @inventory.destroy, using #destroy action?

    respond_to do |format|
      format.js do
        @item = params[:uid].objectify_uid if params[:uid].present?
      end
      format.html do
        @inventories = Inventory.all.order(date: :desc)
      end
    end
  end

  private

  def find_owner_from_acronym(owner)
    Technology.status_worthy.map { |t| [t.owner_acronym, t.owner] }.uniq.to_h[owner]
  end

  def history_params
    params.permit(:item_class, :item_id)
  end

  def set_inventory
    authorize @inventory = Inventory.find(params[:id])
  end

  def technologies_params
    params.require(:inventory).permit technologies: []
  end
end
