# frozen_string_literal: true

class AssembliesController < ApplicationController
  before_action :set_combination, :authorize_assembly
  before_action :set_assembly, only: %i[edit update destroy]
  before_action :create_assembly, only: %i[new]

  def edit
    respond_to do |format|
      format.js { render 'edit' }
    end
  end

  def update
    if @assembly.update(assembly_params)
      @message = 'Assembly updated!'
      @msg_type = 'success'
    else
      @assembly.reload
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
    respond_to do |format|
      format.js { render 'new' }
    end
  end

  def create
    # Check if assembly already exists
    @assembly = @combination.assemblies.find_or_initialize_by assembly_params.except(:quantity)

    @assembly.quantity = assembly_params[:quantity]

    new_record = @assembly.new_record?
    success_message = new_record ? 'Assembly created!' : 'Found existing assembly and updated it.'

    if @assembly.save
      @message = success_message
      @msg_type = 'success'
    else
      @message = 'There was an error making the assembly.'
      @msg_type = 'danger'
    end

    # TODO: Can just redirect_to edit_combination_path(@combination.uid)
    # Or can <%= j render 'assembly_edit', collection: @assembly %>
    respond_to do |format|
      format.js do
        if new_record
          render 'create'
        else
          render 'update'
        end
      end
    end
  end

  def destroy
    if @assembly.destroy
      @message = 'Assembly deleted.'
      @msg_type = 'success'
    else
      @message = 'Failed to delete.'
      @msg_type = 'danger'
    end

    respond_to do |format|
      format.js do
        render 'delete'
      end
    end
  end

  def price; end

  private

  def authorize_assembly
    authorize Assembly
  end

  def create_assembly
    @assembly = @combination.assemblies.new
  end

  def set_assembly
    authorize @assembly = Assembly.find(params[:id])
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
