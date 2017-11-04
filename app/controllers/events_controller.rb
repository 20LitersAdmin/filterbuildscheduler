class EventsController < ApplicationController
  def index
    our_events = policy_scope(Event)
    @events = our_events.future
    @past_events = our_events.past
  end

  def show
    @event = Event.find(params[:id])
    @registration = Registration.where(user: current_user, event: @event).first_or_initialize
  end

  def new
    @event = Event.new
  end

  def update
    @event = Event.find(params[:id])
    @event.update(event_params)
  end

  def edit
    @event = Event.find(params[:id])
  end

  def create
    Event.create!(event_params)
    redirect_to action: :index
  end

  def delete
    @event = authorize Event.find(params[:id])
    @event.delete
    redirect_to events_path
  end

  private

  def event_params
    params.require(:event).permit :title,
                                  :start_time,
                                  :end_time,
                                  :location_id,
                                  :technology_id,
                                  :min_leaders,
                                  :max_leaders,
                                  :min_registrations,
                                  :max_registrations,
                                  :is_private
  end
end
