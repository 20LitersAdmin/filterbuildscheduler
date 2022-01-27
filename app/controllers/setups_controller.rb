# frozen_string_literal: true

class SetupsController < ApplicationController
  before_action :set_event
  before_action :set_setup, only: %i[edit update]
  before_action :set_crew_members, only: %i[new create edit update]

  def show; end

  def new
    @setup = Setup.new(event: @event)
  end

  def create
    @setup = Setup.new(event: @event, creator: current_user)
    if @setup.update(setup_params)
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

  def destroy; end

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
