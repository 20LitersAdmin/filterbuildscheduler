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
      if @setup.users.empty?
        @setup.users << current_user
        SetupMailer.notify(@setup, current_user).deliver_later if @setup.in_the_future?
      elsif @setup.in_the_future?
        @setup.users.each do |user|
          SetupMailer.notify(@setup, user).deliver_later
        end
      end
      flash[:success] = 'Setup event created.'
      redirect_to setup_events_path
    else
      render 'new'
    end
  end

  def edit; end

  def update
    # only send SetupMailer#notify emails to users added, not to already existing users
    old_ids = @setup.user_ids
    new_ids = setup_params[:user_ids].reject!(&:empty?).map(&:to_i) - old_ids

    if @setup.update(setup_params)
      if @setup.in_the_future? && new_ids.any?
        new_ids.each do |id|
          SetupMailer.notify(@setup, User.setup_crew.find(id)).deliver_later
        end
      end

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
      SetupMailer.notify(@setup, current_user).deliver_later if @setup.in_the_future?
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
