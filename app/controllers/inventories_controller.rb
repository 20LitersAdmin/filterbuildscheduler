# frozen_string_literal: true

class InventoriesController < ApplicationController
  def index
    @latest = Inventory.latest
    @inventories = Inventory.former

    authorize @latest
  end

  def show
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| - c.name }

    if @inventory.type_for_params == 'manual'
      # show only what's ready for shipping
      @primary_components = Component.where(completed_tech: true).map(&:id)
      @primary_component_counts = @inventory.counts.where(component_id: @primary_components).sort_by { |c| - c.name }
    else
      # show only what's changed
      @diff_counts = @inventory.counts.where.not(user_id: nil).sort_by { |c| - c.name }
    end

    @event = Event.find(@inventory.event_id) if @inventory.type_for_params == 'event'

    @latest = Inventory.latest_completed
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

    @technologies = Technology.list_worthy.order(name: :asc)
  end

  def create
    @date = inventory_params[:date]

    @matching = Inventory.where(date: Date.parse(@date)).latest

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

    if @matching.present? && @matching.type_for_params == @type
      # No two inventories of the same type on the same day
      flash[:warning] = "A #{@type} inventory already exists for #{inventory_params[:date]}, please use that one."
      return redirect_to inventories_path
    end

    authorize @inventory = Inventory.create(inventory_params)
    @inventory.save

    CountCreate.new(@inventory, technologies_params, current_user)

    if @inventory.errors.any?
      flash[:warning] = @inventory.errors.first.join(': ')
    else
      flash[:success] = 'The inventory has been created.'
      redirect_to inventories_path
    end
  end

  def edit
    authorize @inventory = Inventory.find(params[:id])
    @counts = @inventory.counts.sort_by { |c| [c.sort_by_user, - c.name] }
    @uncounted = @inventory.counts.where(user_id: nil).count

    @techs = Technology.list_worthy

    @inventory.update_column(:completed_at, nil) if params[:unlock] == 'true'
  end

  def update
    authorize @inventory = Inventory.find(params[:id])

    @inventory.update(inventory_params)

    # set count.extrapolated_count field values for all counts that are parts
    Extrapolate.new(@inventory)

    # set :last_received_at and :last_received_quantity on active counts
    Receive.new(@inventory)

    InventoryMailer.delay.notify(@inventory, current_user) if @inventory.type_for_params == 'manual' || @inventory.has_items_below_minimum?

    redirect_to inventories_path
  end

  def order
    # TODO: Don't do this through Inventory && Counts.

    authorize @inventory = Inventory.latest_completed

    @selected_owner_acronym = params[:owner] if params[:owner].present?
    @selected_owner = @selected_owner_acronym ? find_owner_from_acronym(@selected_owner_acronym) : nil
    @technologies = @selected_owner ? Technology.status_worthy.where(owner: @selected_owner) : Technology.status_worthy

    @owners_select = Technology.status_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
    @technologies_select = @technologies.map { |t| [t.name, t.id] }

    @selected_tech_id = @technologies.where(id: params[:tech])&.first&.id if params[:tech].present?
    @selected_tech = @technologies.find(@selected_tech_id) if @selected_tech_id

    @low_counts =
      if @selected_tech_id
        @inventory.counts.select { |c| c.reorder? && c.technologies.map(&:id).include?(@selected_tech_id) }
      elsif @selected_owner_acronym
        @inventory.counts.select { |c| c.reorder? && c.owner.include?(@selected_owner_acronym) }
      else
        @inventory.counts.select(&:reorder?)
      end

    @order_counts = Count.where(id: @low_counts.map(&:id))
    @suppliers = @order_counts.map(&:supplier).uniq

    @no_supplier = @order_counts.select { |c| c.supplier.nil? }
  end

  def order_all
    @selected_owner_acronym = params[:owner] if params[:owner].present?
    @selected_owner = @selected_owner_acronym ? find_owner_from_acronym(@selected_owner_acronym) : nil
    @technologies = @selected_owner ? Technology.status_worthy.where(owner: @selected_owner) : Technology.status_worthy

    @owners_select = Technology.status_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
    @technologies_select = @technologies.map { |t| [t.name, t.id] }

    @selected_tech_id = @technologies.find(params[:tech]).id if params[:tech].present?
    @selected_tech = @technologies.find(@selected_tech_id) if @selected_tech_id

    if @selected_tech_id
      parts = Part.all.select { |p| p.technologies.map(&:id).include?(@selected_tech_id) }
      materials = Material.all.select { |m| m.technologies.map(&:id).include?(@selected_tech_id) }
    elsif @selected_owner_acronym
      parts = Part.all.select { |p| p.owner.include?(@selected_owner_acronym) }
      materials = Material.all.select { |m| m.owner.include?(@selected_owner_acronym) }
    else
      parts = Part.all
      materials = Material.all
    end

    @items = [parts, materials].flatten
    @suppliers = [parts.map(&:supplier).uniq, materials.map(&:supplier).uniq].flatten.uniq

    # Counts without a supplier
    @no_supplier = @items.select { |item| item.supplier.nil? }
  end

  def status
    authorize @inventory = Inventory.latest_completed

    @techs = Technology.status_worthy

    @finder = 'status'
  end

  def paper
    @print_navbar = true
    authorize @inventory = Inventory.latest
    @counts = @inventory.counts.sort_by { |c| [c.group_by_tech, c.name] }
  end

  def destroy
    authorize @inventory = Inventory.find(params[:id])
  end

  def financials
    authorize @latest = Inventory.latest_completed
    @counts = @latest.counts

    @scope = params[:group]

    case @scope
    when 'owner'
      @owners = Technology.order(:owner).finance_worthy.map { |t| [t.owner, t.owner_acronym] }.uniq
    when 'technology'
      @technologies = Technology.order(:owner, :name).finance_worthy
    else # un-grouped
      @built_counts = @counts.joins(:component).where('components.completed_tech = ?', true)
      @val_unbuilt = @counts.where(component_id: nil).map(&:avail_value).sum
      @val_built = @built_counts.map(&:avail_value).sum
      @val_ttl = @val_built + @val_unbuilt
    end
  end

  private

  def inventory_params
    params.require(:inventory).permit :date,
                                      :reported,
                                      :receiving,
                                      :shipping,
                                      :manual,
                                      :deleted_at,
                                      :event_id,
                                      :completed_at,
                                      counts_attributes:
                                        %i[
                                          id
                                          user_id
                                          inventory_id
                                          component_id
                                          part_id
                                          material_id
                                          loose_count
                                          unopened_boxes_count
                                          deleted_at
                                        ]
  end

  def technologies_params
    params.require(:inventory).permit technologies: []
  end

  def find_owner_from_acronym(owner)
    Technology.status_worthy.map { |t| [t.owner_acronym, t.owner] }.uniq.to_h[owner]
  end
end
