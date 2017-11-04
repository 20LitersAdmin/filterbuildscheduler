class EventsController < ApplicationController

  def delete
    @event = authorize Event.find(params[:id])
    @event.delete
    redirect_to events_path
  end

end
