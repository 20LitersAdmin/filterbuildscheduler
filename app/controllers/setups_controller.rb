# frozen_string_literal: true

class SetupsController < ApplicationController
  before_action :set_event
  before_action :set_setup, only: %i[edit update register destroy]
  before_action :set_crew_members, only: %i[new create edit update]

  def show; end

  def new
    authorize @setup = Setup.new(event: @event)
  end

  def create
    authorize @setup = Setup.new(event: @event, creator: current_user)

    if @setup.update(setup_params)
      @setup.users << current_user if @setup.users.empty?
      flash[:success] = 'Setup event create.'
      redirect_to setup_events_path
    else
      render 'new'
    end
  end

  def edit; end

  def update
    if @setup.update(setup_params)
      flash[:success] = 'Setup event updated.'
      redirect_to setup_events_path
    else
      render 'edit'
    end
  end

  def destroy
    @setup.destroy

    flash[:success] = 'Setup event deleted'
    redirect_to setup_events_path
  end

  def register
    case params[:record_action]
    when 'register'
      @setup.users.push(current_user)
      @flash_type = :success
      @flash_message = 'You are now registered to setup!'
    when 'deregister'
      @setup.users.delete(current_user)
      @flash_type = :notice
      @flash_message = 'You cancelled your registration for this setup.'

      if @setup.users.empty?
        @setup.destroy
        @flash_message = 'You cancelled this setup event.'
      end
    end

    flash[@flash_type] = @flash_message
    redirect_to setup_events_path
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_setup
    authorize @setup = Setup.find(params[:id])
  end

  def set_crew_members
    @setup_crew_members = User.setup_crew
  end

  def setup_params
    params.require(:setup).permit :date,
                                  user_ids: []
  end
end
