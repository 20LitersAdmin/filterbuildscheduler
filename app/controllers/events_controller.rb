class EventsController < ApplicationController
  acts_as_token_authentication_handler_for User, only: [:delete]

  def index
    our_events = policy_scope(Event).includes(:location, registrations: :user)
    @events = our_events.future
    if current_user&.is_leader?
      @past_events = our_events.past
    end
    @user = current_user
  end

  def show
    @event = Event.find(params[:id])

    @technology = @event.technology
    if @technology.img_url.present?
      @tech_img = @technology.img_url
    end

    if @technology.info_url.present?
      @tech_info = @technology.info_url
    end

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
    authorize @event

    @event.update(event_params)

    if @event.errors.any?
      flash[:alert] = @event.errors.first.join(": ")
      redirect_to edit_event_path(@event)
    else
      redirect_to event_path(@event)
    end
  end

  def edit
    @event = Event.find(params[:id])
    authorize @event

    if (current_user&.is_admin || @registration&.leader?) && @event.start_time < Time.now
      @show_advanced = true
    else
      @show_advanced = false
    end
  end

  def create
    @event = Event.create(event_params)
    authorize @event

    if @event.errors.any?
      flash[:alert] = @event.errors.first.join(": ")
      redirect_to new_event_path
    else
      flash[:success] = "The event has been created."
      EventMailer.created(@event, current_user).deliver!
      redirect_to action: :index
    end
  end

  def delete
    @event = authorize Event.find(params[:id])
    authorize @event
    EventMailer.cancelled(@event, current_user).deliver!
    @event.delete!
    flash[:success] = "The event has been cancelled."
    if params[:authentication_token].present?
      redirect_to home_path
    else
      redirect_to events_path
    end
  end

  def attendance
    @event = Event.find(params[:id])
    authorize @event, :edit?

    @registrations = Registration.where(event_id: @event.id)

    @print_blanks = @event.max_registrations - @event.total_registered + 5
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
                                  :description,
                                  :item_goal,
                                  :technologies_built,
                                  :boxes_packed,
                                  :attendance,
                                  registrations_attributes: [ :id, :attended ]
  end
end
