class EventsController < ApplicationController
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
    @registration = Registration.where(user: current_user, event: @event).first_or_initialize

    # decide whether or not to show the event with a stupidly complicated nested if
    if @event.in_the_past?
      if current_user&.is_admin || @registration.leader?
        # past events can only be viewed by admins or those who lead the event.
        @show_event = true
        @show_admin_registration = true
      else
        @show_event = false
      end
    else # event is in the future
      @show_event = true
    end

    # take action on that decision
    if @show_event == true
      @technology = @event.technology
      if @technology.img_url.present?
        @tech_img = @technology.img_url
      end

      if @technology.info_url.present?
        @tech_info = @technology.info_url
      end



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
    else
      flash[:warning] = "You don't have permission"
      redirect_to action: :index
    end
  end

  def new
    @event = Event.new
  end

  def update
    @event = Event.find(params[:id])
    authorize @event

    @event.start_time         = params[:event][:start_time]
    @event.end_time           = params[:event][:end_time]
    @event.title              = params[:event][:title]
    @event.description        = params[:event][:description]
    @event.min_registrations  = params[:event][:min_registrations]
    @event.max_registrations  = params[:event][:max_registrations]
    @event.min_leaders        = params[:event][:min_leaders]
    @event.max_leaders        = params[:event][:max_leaders]
    @event.location_id        = params[:event][:location_id]
    @event.technology_id      = params[:event][:technology_id]
    @event.is_private         = params[:event][:is_private]
    @event.item_goal          = params[:event][:item_goal]
    @event.technologies_built = params[:event][:technologies_built]
    @event.attendance         = params[:event][:attendance]
    @event.boxes_packed       = params[:event][:boxes_packed]

    @admins_notified = ""
    @users_notified = ""

    if @event.start_time_was > Time.now && (@event.start_time_changed? || @event.end_time_changed? || @event.location_id_changed? || @event.technology_id_changed? || @event.is_private_changed?)
      # EventMailer.delay.changed(@event, current_user)
      EventMailer.changed(@event, current_user).deliver!
      @admins_notified = "Admins notified."
      if @event.registrations.exists? && ( @event.start_time_changed? || @event.end_time_changed? || @event.location_id_changed? || @event.technology_id_changed? )
        @event.registrations.each do |registration|
          # RegistrationMailer.delay.event_changed(registration, @event)
          RegistrationMailer.event_changed(registration, @event).deliver!
          @users_notified = "All registered builders notified."
        end
      end
    end

    if @event.save
      flash[:success] = "Event updated"
      redirect_to event_path(@event)
    else
      flash[:warning] = @event.errors.first.join(": ")
      redirect_to edit_event_path(@event)
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
      flash[:warning] = @event.errors.first.join(": ")
      redirect_to new_event_path
    else
      flash[:success] = "The event has been created."
      EventMailer.delay.created(@event, current_user)
      redirect_to action: :index
    end
  end

  def delete
    @event = authorize Event.find(params[:id])
    authorize @event
    @event.delete!
    flash[:success] = "The event has been cancelled."
    redirect_to events_path
  end

  def attendance
    @event = Event.find(params[:id])
    authorize @event, :edit?

    @registrations = @event.registrations.ordered_by_user_lname

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
                                  registrations_attributes: [ :id, :user_id, :event_id, :attended, :leader, :guests_registered, :guests_attended ]
  end
end
