class EventsController < ApplicationController
  def index
    @events = Event.all()
  end

  def show
    @event = Event.find(params[:id])
    @registration = Registration.new(user: current_user, event: @event)
  end
end
