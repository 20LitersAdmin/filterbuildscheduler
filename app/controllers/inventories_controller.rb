# frozen_string_literal: true

class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[show edit update destroy]
  before_action :authorize_inventory, only: %i[order order_all]

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
    return redirect_to inventory_path(@inventory) if @inventory.counts.none?

    # This view is where inventory counting gets performed

    @counts = @inventory.counts.sort_by { |c| [c.sort_by_status, - c.item.name] }
    @uncounted = "#{view_context.pluralize(@inventory.counts.untouched.size, 'item')} uncounted."

    @techs = Technology.list_worthy
  end

  def update
    # @inventory only gets updated once, on complete, no incremental updates
    @inventory.completed_at = Time.now.localtime

    # If completed_at is present, Inventory#after_update triggers:
    # ProduceableJob
    # CountTransferJob
    @inventory.save

    # NOTE: the unless is probably unnecessary as event-based inventories don't hit the update action, but just being overly cautious
    InventoryMailer.delay(queue: 'inventory_mailer').notify(@inventory, current_user) unless @inventory.event_based?

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

  def order
    @technologies = Technology.list_worthy

    @technologies_select = @technologies.map { |t| [t.name, t.id] }

    @selected_tech = @technologies.find(params[:tech]) if params[:tech].present?

    if @selected_tech
      @selected_tech_id = @selected_tech.id
      @selected_tech_uid = @selected_tech.uid

      parts = Part.below_minimums.orderable.select { |part| part.quantities.keys.include?(@selected_tech_uid) }
      materials = Material.below_minimums.select { |m| m.quantities.keys.include?(@selected_tech_uid) }
    else
      parts = Part.below_minimums.orderable
      materials = Material.below_minimums
    end

    @items = [parts, materials].flatten
    @suppliers = [parts.map(&:supplier).uniq, materials.map(&:supplier).uniq].flatten.uniq.compact

    @items_w_no_supplier = @items.select { |item| item.supplier.nil? }
  end

  def order_all
    @technologies = Technology.list_worthy

    @technologies_select = @technologies.map { |t| [t.name, t.id] }

    @selected_tech = @technologies.find(params[:tech]) if params[:tech].present?

    if @selected_tech
      @selected_tech_id = @selected_tech.id
      @selected_tech_uid = @selected_tech.uid

      parts = Part.orderable.select { |part| part.quantities.keys.include?(@selected_tech_uid) }
      materials = Material.kept.select { |m| m.quantities.keys.include?(@selected_tech_uid) }
    else
      parts = Part.active.orderable
      materials = Material.active
    end

    @items = [parts, materials].flatten
    @suppliers = [parts.map(&:supplier).uniq, materials.map(&:supplier).uniq].flatten.uniq.compact

    @items_w_no_supplier = @items.select { |item| item.supplier.nil? }
  end

  def paper
    @print_navbar = true

    technologies = Technology.active.list_worthy
    components = Component.active
    parts = Part.active
    materials = Material.active

    @items = [technologies, components, parts, materials].flatten
  end

  def history
    respond_to do |format|
      format.js do
        @item = params[:uid].presence&.objectify_uid
        render 'history', layout: 'blank'
      end
      format.html do
        @inventories = Inventory.all.order(date: :desc)
      end
    end
  end

  private

  def authorize_inventory
    authorize Inventory
  end

  def history_params
    params.permit(:item_class, :item_id)
  end

  def inventory_params
    params.require(:inventory).permit :date,
                                      :reported,
                                      :receiving,
                                      :shipping,
                                      :manual,
                                      :event_id,
                                      :completed_at
  end

  def set_inventory
    authorize @inventory = Inventory.find(params[:id])
  end

  def technologies_params
    params.require(:inventory).permit technologies: []
  end
end
