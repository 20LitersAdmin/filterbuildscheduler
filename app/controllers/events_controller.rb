# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :set_event,
                only: %i[
                  attendance
                  destroy
                  edit
                  leader_register
                  leader_unregister
                  leaders
                  poster
                  replicate
                  replicator
                  restore
                  show
                  update
                ]

  def attendance
    @registrations = @event.registrations.active.builders.ordered_by_user_lname

    @print_blanks = @event.max_registrations - @event.total_registered + 5
    @print_navbar = true

    @discarded_registrations = @event.registrations.discarded.builders.ordered_by_user_lname
  end

  def create
    authorize @event = Event.new(event_params)
    if @event.save
      flash[:success] = 'The event has been created.'
      EventMailer.delay(queue: 'event_mailer').created(@event, current_user)
      redirect_to action: :index
    else
      @locations = Location.active.order(:name)
      @technologies = Technology.list_worthy.order(:id).map { |t| ["#{t.name} (#{t.short_name})", t.id] }
      render 'new'
    end
  end

  def destroy
    admins_notified = nil
    users_notified = nil

    # send emails to registrations and leaders before cancelling
    if @event.start_time > Time.now
      EventMailer.cancelled(@event, current_user).deliver_later
      admins_notified = 'Admins notified.'

      if @event.registrations.exists?
        @event.registrations.each do |registration|
          RegistrationMailer.event_cancelled(registration, @event).deliver_later
          registration.discard
        end
        users_notified = 'All registered builders notified.'
      end
    end

    if @event.discard
      flash[:success] = "Event cancelled. #{admins_notified} #{users_notified}"
      redirect_to root_path
    else
      flash[:warning] = @event.errors.first.join(': ')
      redirect_to edit_event_path(@event)
    end
  end

  def edit
    @locations = Location.active.order(:name)
    @technologies = Technology.list_worthy.order(:id).map { |t| ["#{t.name} (#{t.short_name})", t.id] }
  end

  def index
    our_events = policy_scope(Event)
    @events = our_events.future
    @user = current_user

    begin
      liters_tracker = LitersTrackerClient.new
      @progress_date = liters_tracker.as_of_date
      @stats = liters_tracker.stat_ary
    rescue NoMethodError
      @stats = []
    end
  end

  def lead
    @user = current_user
    @events = Event.needs_leaders

    authorize Event
  end

  def leaders
    @leaders = User.leaders
    @already_registered_leaders = User.find(@event.registrations.active.leaders.pluck(:user_id))
    @remaining_leaders = @leaders - @already_registered_leaders
  end

  def leader_unregister
    @registration = @event.registrations.active.leaders.where(user_id: params[:user_id]).first

    if @registration.blank?
      flash[:error] = 'Oops, something went wrong.'
    else
      # actually delete, not discard
      @registration.delete
      flash[:success] = "#{@registration.user.name} was unregistered."
    end

    redirect_to leaders_event_path(@event)
  end

  def leader_register
    @registration = @event.registrations.where(user_id: params[:user_id]).first_or_initialize

    @registration.leader = true
    @registration.undiscard if @registration.discarded?
    @registration.save
    RegistrationMailer.created(@registration).deliver_now

    flash[:success] = "Registered #{@registration.user.name}."
    redirect_to leaders_event_path(@event)
  end

  def new
    @locations = Location.active.order(:name)
    @technologies = Technology.list_worthy.order(:id).map { |t| ["#{t.name} (#{t.short_name})", t.id] }

    if params[:source_event].blank?
      @indicator = 'new'
      authorize @event = Event.new
    else
      @indicator = 'duplicate'
      authorize @event = Event.find(params[:source_event]).dup
    end
  end

  def poster
    @technology = @event.technology
    @tech_img = @technology.display_image
    @location = @event.location
    @location_img = @location.image

    @tech_blurb = @technology.public_description

    @child_statement_email =
      if @technology.family_friendly
        'children as young as 4 can participate'
      else
        'this event is best for ages 12 and up'
      end

    @print_navbar = true
  end

  def replicate
    @replicator = Replicator.new
  end

  # /events/replicate_occurrences
  # AJAX from #replicate and #replicator (on error) views, shows recurring dates as a list on the page
  def replicate_occurrences
    return render(json: 'missing param', status: :unprocessable_entity) if params[:f].blank? || params[:s].blank? || params[:e].blank? || params[:o].blank?

    replicator = Replicator.new

    replicator.tap do |r|
      # r.event_id = Integer(params[:id])
      r.start_time = Time.parse(params[:s])
      r.end_time = Time.parse(params[:e])
      r.frequency = params[:f]
      r.occurrences = Integer(params[:o])
    end

    render json: replicator.date_array
  end

  def replicator
    @replicator = Replicator.new(replicator_params)

    @replicator.user = current_user

    if @replicator.go!(@event)
      flash[:success] = 'Event was successfully replicated!'
      redirect_to root_path
    else
      flash[:error] = @replicator.errors.full_messages.to_sentence
      render :replicate
    end
  end

  def setup
    @user = current_user
    @events = Event.future

    authorize Event
  end

  def show
    # TODO: Check that discarded technologies and locations still show up
    @registration = @event.registrations.active.where(user: current_user).first_or_initialize

    @registration.leader = (params[:leader].present? && current_user&.can_lead_event?(@event)) if @registration.new_record?

    @tech_img = @event.technology&.display_image

    @tech_info = @event.technology&.info_url if @event.technology&.info_url.present?

    @location = @event.location

    @location_img = @event.location&.image

    @show_edit = (current_user&.is_admin || @registration&.leader?)

    @leaders = @event.registrations.active.leaders
  end

  def update
    # this also sets submitted registrations as attended
    @event.assign_attributes(event_params)

    admins_notified = nil
    users_notified = nil
    results_emails_sent = nil
    inventory_created = nil

    if @event.should_notify_admins?
      # Can't use delayed_job because ActiveModel::Dirty doesn't persist
      EventMailer.changed(@event, current_user).deliver_now
      admins_notified = 'Admins notified.'
    end

    if @event.should_notify_builders?
      @event.registrations.each do |registration|
        # Can't use delayed_job because ActiveModel::Dirty doesn't persist
        RegistrationMailer.event_changed(registration, @event).deliver_now
      end
      users_notified = 'All registered builders notified.'
    end

    if @event.should_send_results_emails? && params[:send_report].present?
      send_results_emails = true
      @event.emails_sent = true
      results_emails_sent = 'Attendees notified of results.'
    end

    # set a variable now, while ActiveModel::Dirty can inspect *_changed?
    # then trigger EventInventoryJob after @event.save
    create_inventory = true if @event.should_create_inventory?

    if @event.save
      @event.reload

      # Only trigger stuff if the event is actually complete.
      if @event.complete?
        # shouldn't be any need for .active here because registrations were just marked as attended, there hasn't been a chance to discard them.
        @event.registrations.attended.each do |r|
          RegistrationMailer.event_results(r).deliver_later if send_results_emails
          KindfulClient.new.delay(queue: 'kindful_client').import_user_w_note(r)
        end

        EventInventoryJob.perform_later(@event) if create_inventory

        inventory_created = 'Inventory created. ' if create_inventory
      end

      flash[:success] = "Event updated. #{admins_notified} #{users_notified} #{results_emails_sent} #{inventory_created}"

      redirect_to event_path(@event)
    else
      flash[:danger] = 'There was a problem saving this event report.'
      @locations = Location.active.order(:name)
      @technologies = Technology.list_worthy.order(:id).map { |t| ["#{t.name} (#{t.short_name})", t.id] }
      render 'edit'
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
                                  :description,
                                  :item_goal,
                                  :impact_results,
                                  :technologies_built,
                                  :boxes_packed,
                                  :attendance,
                                  :contact_name,
                                  :contact_email,
                                  registrations_attributes: %i[id user_id event_id attended leader guests_registered guests_attended]
  end

  def replicator_params
    params.require(:replicator).permit :start_time,
                                       :end_time,
                                       :frequency,
                                       :occurrences,
                                       :replicate_leaders
  end

  def set_event
    authorize @event = Event.find(params[:id])
  end
end
