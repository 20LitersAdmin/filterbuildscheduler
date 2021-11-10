# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :find_stale
  before_action :set_event, only: %i[show edit update attendance poster replicate replicator restore leaders leader_unregister leader_register]

  def index
    our_events = policy_scope(Event)
    @events = our_events.future
    @user = current_user

    @past_events = our_events.needs_report if @user&.admin_or_leader?

    begin
      liters_tracker = LitersTrackerClient.new
      @progress_date = liters_tracker.as_of_date
      @stats = liters_tracker.stat_ary
    rescue NoMethodError
      @stats = []
    end
  end

  def show
    @registration = @event.registrations.where(user: current_user).first_or_initialize

    @registration.leader = (params[:leader].present? && current_user&.can_lead_event?(@event)) if @registration.new_record?

    @tech_img = @event.technology.display_image

    @tech_info = @event.technology.info_url if @event.technology&.info_url.present?

    @location = @event.location

    @location_img = @event.location.image

    @show_edit = (current_user&.is_admin || @registration&.leader?)

    @leaders = @event.registrations.leaders

    @user = current_user || User.new
  end

  def new
    if params[:source_event].blank?
      @indicator = 'new'
      authorize @event = Event.new
    else
      @indicator = 'duplicate'
      authorize @event = Event.find(params[:source_event]).dup
    end
  end

  def create
    authorize @event = Event.new(event_params)
    if @event.save
      flash[:success] = 'The event has been created.'
      EventMailer.delay.created(@event, current_user)
      redirect_to action: :index
    else
      render 'new'
    end
  end

  def edit
    @show_report = current_user&.admin_or_leader? && @event.start_time < Time.now

    @too_old = (Date.today - @event.end_time.to_date).round > 14
  end

  def update
    @event.assign_attributes(event_params)

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
        @event.registrations.where(attended: true).each do |r|
          RegistrationMailer.delay.event_results(r) if send_results_emails
          KindfulClient.new.delay.import_user_w_note(r)
        end

        EventInventoryJob.perform_later(@event) if create_inventory
      end

      flash[:success] = "Event updated. #{admins_notified} #{users_notified} #{results_emails_sent} #{inventory_created}"

      redirect_to event_path(@event)
    else
      flash[:danger] = 'There was a problem saving this event report.'
      @show_advanced = true
      render 'edit'
    end
  end

  def destroy
    # send emails to registrations and leaders before cancelling
    if @event.start_time > Time.now
      EventMailer.delay.cancelled(@event, current_user)
      @admins_notified = 'Admins notified.'

      if @event.registrations.exists?
        @event.registrations.each do |registration|
          RegistrationMailer.delay.event_cancelled(registration, event)
        end
        @users_notified = 'All registered builders notified.'
      end

    end

    if @event.discard
      flash[:success] = "Event cancelled. #{@admins_notified} #{@users_notified}"
      redirect_to root_path
    else
      flash[:warning] = @event.errors.first.join(': ')
      redirect_to edit_event_path(@event)
    end
  end

  def cancelled
    authorize @cancelled_events
    @user = current_user
  end

  def closed
    authorize @closed_events
    @user = current_user
  end

  def lead
    @user = current_user
    @events = []

    Event.future.each do |e|
      @events << e if e.needs_leaders?
    end

    authorize Event
  end

  def leaders
    @leaders = User.leaders
    @already_registered_leaders = User.find(@event.registrations.leaders.pluck(:user_id))
    @remaining_leaders = @leaders - @already_registered_leaders
  end

  def leader_unregister
    @registration = @event.registrations.leaders.where(user_id: params[:user_id]).first

    if @registration.blank?
      flash[:error] = 'Oops, something went wrong.'
    else
      @registration.delete
      flash[:success] = "#{@registration.user.name} was unregistered."
    end

    redirect_to leaders_event_path(@event)
  end

  def leader_register
    @registration = @event.registrations.where(user_id: params[:user_id]).first_or_initialize

    @registration.leader = true
    @registration.restore if @registration.deleted?
    @registration.save
    RegistrationMailer.created(@registration).deliver_now

    flash[:success] = "Registered #{@registration.user.name}."
    redirect_to leaders_event_path(@event)
  end

  def restore
    authorize @event = Event.discarded.find(params[:id])
    if params[:recursive] == 'false'
      Event.restore(@event.id)
      flash[:success] = 'Event restored but not registrations.'
    else
      Event.restore(@event.id, recursive: true)
      flash[:success] = 'Event and associated registrations restored.'
    end

    Event.discarded.exists? ? redirect_to(cancelled_events_path) : redirect_to(events_path)
  end

  def replicate
    @replicator = Replicator.new
  end

  def replicate_occurrences
    return if params[:f].blank? || params[:s].blank? || params[:e].blank?

    replicator = Replicator.new

    replicator.tap do |r|
      r.event_id = Integer(params[:id])
      r.start_time = Time.parse(params[:s])
      r.end_time = Time.parse(params[:e])
      r.frequency = params[:f]
      r.occurrences = params[:o].blank? ? 1 : Integer(params[:o])
    end

    render json: replicator.date_array
  end

  def replicator
    replicator = Replicator.new(replicator_params)

    replicator.event_id = @event.id
    replicator.initiator = current_user

    if replicator.go!
      flash[:success] = 'Event was successfully replicated!'
      redirect_to root_path
    else
      flash[:warning] = replicator.errors.messages
      # @event = Event.find(params[:id])
      @replicator = Replicator.new
      render :replicate
    end
  end

  def attendance
    @registrations = @event.registrations.where.not(leader: true).ordered_by_user_lname

    @print_blanks = @event.max_registrations - @event.total_registered + 5
    @print_navbar = true
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
                                  registrations_attributes: %i[id user_id event_id attended leader guests_registered guests_attended]
  end

  def replicator_params
    params.require(:replicator).permit :start_time,
                                       :end_time,
                                       :frequency,
                                       :occurrences,
                                       :replicate_leaders
  end

  def find_stale
    @cancelled_events = Event.discarded
    @closed_events = Event.closed
  end

  def set_event
    # TODO: this could be bad if navigating from one event directly to another event?
    authorize @event ||= Event.find(params[:id])
  end
end
