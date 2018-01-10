class EventsController < ApplicationController
  def index
    our_events = policy_scope(Event).includes(:location, registrations: :user)
    @events = our_events.future
    if current_user&.is_leader?
      @past_events = our_events.past
    end
    @user = current_user

    @cancelled_events = Event.only_deleted
  end

  def show
    authorize @event = Event.find(params[:id])
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
      if @event.technology.img_url.present?
        @tech_img = @event.technology.img_url
      end
      if @event.technology.info_url.present?
        @tech_info = @event.technology.info_url
      end
      if @event.location.photo_url.present?
        @location_img = @event.location.photo_url
      end

      if (current_user&.is_admin || @registration&.leader?) && @event.start_time < Time.now
        @show_report = true
        @registrations = @event.registrations.includes(:user).order("users.is_leader").order("users.lname")
      else
        @show_report = false
      end

      if (current_user&.is_admin || @registration&.leader?)
        @show_edit = true
      else
        @show_edit = false
      end
    else
      flash[:warning] = "That event is not available, Sorry."
      redirect_to action: :index
    end
  end

  def new
    authorize @event = Event.new
  end

  def create
    authorize @event = Event.new(event_params)
    authorize @event

    if @event.save
      flash[:success] = "The event has been created."
      EventMailer.delay.created(@event, current_user)
      redirect_to action: :index
    else
      render 'new'
    end
  end

  def edit
    authorize @event = Event.find(params[:id])

    if (current_user&.is_admin || @registration&.leader?) && @event.start_time < Time.now
      @show_advanced = true
    else
      @show_advanced = false
    end
  end

  def update
    authorize @event = Event.find(params[:id])

    modified_params = event_params.dup

    if event_params[:technologies_built] == ''
      modified_params[:technologies_built] = @event.technologies_built || 0
    end
    if event_params[:boxes_packed] == ''
      modified_params[:boxes_packed] = @event.boxes_packed || 0
    end
    if event_params[:item_goal] == ''
      modified_params[:item_goal] = @event.item_goal || 0
    end

    @event.assign_attributes(modified_params)

    # CREATE AN INVENTORY WHEN AN EVENT REPORT IS SUBMITTED UNDER CERTAIN CONDITIONS.
    # Fields in question: technologies_built, boxes_packed
    # Conditions: They're not negative AND ( they're not both 0 OR they weren't zero but now they are. )

    # Condition: Neither number is negative
    @positive_numbers = false
    if @event.technologies_built >= 0 && @event.boxes_packed >= 0
      @positive_numbers = true
    end

    # Condition: they're not both 0
    @more_than_zero = @event.technologies_built + @event.boxes_packed

    # Condition: they weren't zero, but now they are:
    @changed_to_zero = false
    if @event.technologies_built_was != 0 && @event.technologies_built == 0
      @changed_to_zero = true
    end
    if @event.boxes_packed_was != 0 && @event.boxes_packed == 0
      @changed_to_zero = true
    end

    # combine conditions
    if @positive_numbers && ( @more_than_zero > 0 || @changed_to_zero )
      @inventory = Inventory.where(event_id: @event.id).first_or_initialize
      @inventory.update(date: Date.today, completed_at: Time.now)

      if @inventory.counts.count == 0
        InventoriesController::CountCreate.new(@inventory)
      end

      # determine the values to use when populating the count
      if event_params[:technologies_built] == ''
        @loose = nil
      elsif @event.technologies_built_changed?
        @loose = @event.technologies_built - @event.technologies_built_was
      else
        @loose = @event.technologies_built
      end

      if event_params[:boxes_packed] == ''
        @box = nil
      elsif @event.boxes_packed_changed?
        @box = @event.boxes_packed - @event.boxes_packed_was
      else
        @box = @event.boxes_packed
      end

      # record the results of the event in the inventory
      CountPopulate.new(@loose, @box, @event, @inventory, current_user.id)
      # extrapolate out the full inventory given the new results
      InventoriesController::Extrapolate.new(@inventory)

      
    end

    @admins_notified = ""
    @users_notified = ""

    if @event.start_time_was > Time.now && (@event.start_time_changed? || @event.end_time_changed? || @event.location_id_changed? || @event.technology_id_changed? || @event.is_private_changed?)
      EventMailer.delay.changed(@event, current_user)
      #EventMailer.changed(@event, current_user).deliver!
      @admins_notified = "Admins notified."
      if @event.registrations.exists? && ( @event.start_time_changed? || @event.end_time_changed? || @event.location_id_changed? || @event.technology_id_changed? )
        @event.registrations.each do |registration|
          RegistrationMailer.delay.event_changed(registration, @event)
          #RegistrationMailer.event_changed(registration, @event).deliver!
          @users_notified = "All registered builders notified."
        end
      end
    end
    
    @send_results_emails = false

    if (@event.attendance_was == nil || @event.attendance_was == 0 ) && @event.attendance > 0
      @send_results_emails = true
      
    end

    if @event.save
      flash[:success] = "Event updated. #{@admins_notified} #{@users_notified}"

      if @send_results_emails == true
        @event.registrations.where(attended: true).each do |r|
          # RegistrationMailer.delay.event_results(r)
          RegistrationMailer.event_results(r).deliver!
        end
      end


      redirect_to event_path(@event)
    else
      if event_params[:technologies_built].present?
        flash[:danger] = "There was a problem saving this event report."
        @registration = Registration.where(user: current_user, event: @event).first_or_initialize
        @location = @event.location
        @technology = @event.technology
        @tech_img = @technology.img_url
        @tech_info = @technology.info_url
        @location_img = @location.photo_url
        @show_event = true
        @show_report = true
        render 'show'
      else
        @show_advanced = true
        render 'edit'
      end
    end
  end

  def destroy
    authorize @event = Event.find(params[:id])

    @admins_notified = ""
    @users_notified = ""

    # send emails to registrations and leaders before cancelling
    if @event.start_time > Time.now
      EventMailer.delay.cancelled(@event, current_user)
      #EventMailer.cancelled(@event, current_user).deliver!
      @admins_notified = "Admins notified."
      if @event.registrations.exists?
        @event.registrations.each do |registration|
          RegistrationMailer.delay.event_cancelled(registration)
          #RegistrationMailer.event_cancelled(registration).deliver!
          @users_notified = "All registered builders notified."
        end
      end
    end

    if @event.destroy
      flash[:success] = "Event cancelled. #{@admins_notified} #{@users_notified}"
      redirect_to root_path
    else
      flash[:warning] = @event.errors.first.join(": ")
      redirect_to edit_event_path(@event)
    end
  end

  def cancelled
    authorize @cancelled_events = Event.only_deleted
    @user = current_user
  end

  def restore
    authorize @event = Event.only_deleted.find(params[:id])
    if params[:recursive] == "false"
      Event.restore(@event.id)
      flash[:success] = "Event restored but not registrations."
    else
      Event.restore(@event.id, recursive: true)
      flash[:success] = "Event and associated registrations restored."
    end

    if Event.only_deleted.exists?
      redirect_to cancelled_events_path
    else
      redirect_to events_path
    end
  end

  def attendance
    @event = Event.find(params[:id])
    authorize @event, :edit?

    @registrations = @event.registrations.where.not(leader: true).ordered_by_user_lname

    @print_blanks = @event.max_registrations - @event.total_registered + 5
    @print_navbar = true
  end

  def poster
    @event = Event.find(params[:id])
    @technology = @event.technology
    @tech_img = @technology.img_url
    @location = @event.location
    @location_img = @location.photo_url

    if @technology.owner == "Village Water Filters"
      @tech_blurb = "Sold at or below cost in over 60 developing countries, this filter is designed to be affordable for those making $2 a day."
    elsif @technology.owner == "20 Liters"
      @tech_blurb = "Distributed to the rural poor in Rwanda, this filter handles the muddy, disgusting water from the Nyabarongo River. Each filter is supported by a network of village-based volunteers, community health workers and local leaders."
    else
      @tech_blurb = ''
    end

    if @technology.family_friendly
      @child_statement_email = "children as young as 4 can participate"
    else
      @child_statement_email = "this event is best for ages 12 and up"
    end

    @print_navbar = true
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
                                  :contact_name,
                                  :contact_email,
                                  registrations_attributes: [ :id, :user_id, :event_id, :attended, :leader, :guests_registered, :guests_attended ]
  end
end
