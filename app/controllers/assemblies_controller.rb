# frozen_string_literal: true

class AssembliesController < ApplicationController
  before_action :authorize_assembly
  before_action :set_assembly, only: %i[open_modal_form update]
  before_action :set_component

  def index
    # show all assembly records in some meaningful way?
    # since we aren't in RailsAdmin
  end

  def edit; end

  def update
    if @assembly.update(assembly_params)
      @message = 'Assembly saved!'
      @msg_type = 'success'
    else
      @message = 'There was an error saving the assembly.'
      @msg_type = 'danger'
    end

    respond_to do |format|
      format.js do
        render 'update'
      end
    end
  end

  def new
    @assembly = Assembly.new

    respond_to do |format|
      format.js { render 'open_modal_form' }
    end
  end

  def create
    @assembly = Assembly.new

    if @assembly.create(assembly_params)
      @message = 'Assembly created!'
      @msg_type = 'success'
    else
      @message = 'There was an error making the assembly.'
      @msg_type = 'danger'
    end

    respond_to do |format|
      format.js do
        render 'update'
      end
    end
  end

  def open_modal_form
    respond_to do |format|
      format.js { render 'open_modal_form' }
    end
  end

  def price; end

  # YAGNI: Calculates how deep the tree goes
  # def downward(assembly)
  #   @depth_ary << assembly.depth
  #   assemblies = assembly.item.sub_assemblies.component_items

  #   assemblies.each do |sub_assembly|
  #     downward(sub_assembly)
  #   end
  # end

  private

  def authorize_assembly
    authorize Assembly
  end

  def set_assembly
    @assembly = Assembly.find(params[:id])
  end

  def set_combination
    # we're mimicing the standard structure, but
    # we're actually passing the `:uid` in place of the `:id`
    # so we can objectify the string to get the @item
    @combination = params[:combination_uid].objectify_uid

    return if @combination.present? && [Technology, Component].include?(@combination.class)

    flash[:alert] = 'Please check UID and try again. Must be a Technology or Component'
    # TODO: Where is the best place to return the browser to if the UID fails && reqest.referrer is blank?
    redirect_to request.referrer || rails_admin.dashboard_path
  end

  def assembly_params
    params.require(:assembly).permit :combination_id,
                                     :combination_type,
                                     :item_id,
                                     :item_type,
                                     :quantity
  end
end
