class EventsController < ApplicationController
  acts_as_token_authentication_handler_for User, only: [:delete]
  def index
    our_events = policy_scope(Event).includes(:location, registrations: :user)
    @events = our_events.future
    if current_user&.is_leader?
      @past_events = our_events.past
    end
  end

  def show
    @event = Event.find(params[:id])

    redirect_to action: :index if @event.in_the_past? && !current_user.is_leader

    @registration = Registration.where(user: current_user, event: @event).first_or_initialize

    if (current_user&.is_admin || @registration&.leader?) && @event.incomplete? && @event.start_time < Time.now
      @show_report = true
    else
      @show_report = false
    end

    if (current_user&.is_admin || @registration&.leader?)
      @show_edit = true
    else
      @show_edit = false
    end
  end

  def new
    @event = Event.new
  end

  def update
    @event = Event.find(params[:id])
    @event.update!(event_params)
    redirect_to event_path(@event)
  end

  def edit
    @event = Event.find(params[:id])

    if (current_user&.is_admin || @registration&.leader?) && @event.start_time < Time.now
      @show_advanced = true
    else
      @show_advanced = false
    end
  end

  def create
    Event.create!(event_params)
    redirect_to action: :index
  end

  def delete
    @event = authorize Event.find(params[:id])
    @event.delete
    flash[:success] = "Your registration has been cancelled."
    if params[:authentication_token].present?
      redirect_to home_path
    else
      redirect_to events_path
    end
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
                                  :is_private,
                                  :item_goal,
                                  :item_results,
                                  :attendance,
                                  registrations_attributes: [ :id, :attended ]
  end
end
