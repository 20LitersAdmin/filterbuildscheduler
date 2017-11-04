class EventsController < ApplicationController

  def index
    @events = Event.future
    @past_events = Event.past
  end

  def show
    @event = Event.find(params[:id])
    @registration = Registration.new(user: current_user, event: @event)
  end

  def new
    @event = Event.new
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
                                  :min_leaders,
                                  :max_leaders,
                                  :min_registrations,
                                  :max_registrations
  end
end
