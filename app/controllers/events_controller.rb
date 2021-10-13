# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :find_stale

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
    authorize @event = Event.find(params[:id])
    @registration = @event.registrations.where(user: current_user).first_or_initialize

    @registration.leader = (params[:leader].present? && current_user&.can_lead_event?(@event)) if @registration.new_record?

    @tech_img = @event.technology.display_image

    @tech_info = @event.technology.info_url if @event.technology&.info_url.present?

    @location = @event.location

    @location_img = @event.location.image

    @show_edit = (current_user&.is_admin || @registration&.leader?)

    @leaders = @event.registrations.registered_as_leader

    @finder = 'show'

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

    @finder = 'new'
  end

  def create
    authorize @event = Event.new(event_params)

    @finder = 'new'
    if @event.save
      flash[:success] = 'The event has been created.'
      EventMailer.delay.created(@event, current_user)
      redirect_to action: :index
    else
      render 'new'
    end
  end

  def edit
    authorize @event = Event.find(params[:id])

    @show_report = current_user&.admin_or_leader? && @event.start_time < Time.now

    @too_old = (Date.today - @event.end_time.to_date).round > 14

    @finder = 'edit'
  end

  def update
    byebug

    authorize @event = Event.find(params[:id])

    modified_params = event_params.dup

    # An event can be updated before the event, with no event report
    # Or after the event, including an event report
    modified_params[:technologies_built] = @event.technologies_built || 0 if event_params[:technologies_built] == ''

    modified_params[:boxes_packed] = @event.boxes_packed || 0 if event_params[:boxes_packed] == ''

    modified_params[:item_goal] = @event.item_goal || 0 if event_params[:item_goal] == ''

    @event.assign_attributes(modified_params)

    @inventory_created = ''
    @admins_notified = ''
    @users_notified = ''
    @results_emails_sent = ''
    # CREATE AN INVENTORY WHEN AN EVENT REPORT IS SUBMITTED UNDER CERTAIN CONDITIONS.
    # Fields in question: technologies_built, boxes_packed
    # Condition: This is the first time the event report is being submitted (@event.emails_sent == false)
    # Conditions: They're not negative AND ( they're not both 0 OR they weren't zero but now they are. )
    # ESCAPE CLAUSE: the event's technology doesn't have a primary_component

    # Condition: Neither number is negative
    @positive_numbers = false
    @positive_numbers = true if @event.technologies_built >= 0 && @event.boxes_packed >= 0

    # Condition: they're not both 0
    @more_than_zero = (@event.technologies_built + @event.boxes_packed).positive?

    # Condition: they weren't zero, but now they are:
    @changed_to_zero = false
    @changed_to_zero = true if @event.technologies_built_was != 0 && @event.technologies_built.zero?
    @changed_to_zero = true if @event.boxes_packed_was != 0 && @event.boxes_packed.zero?

    # combine conditions
    if @positive_numbers && (@more_than_zero || @changed_to_zero) && @event.emails_sent == false

      # determine the values to use when populating the count
      @loose =
        if event_params[:technologies_built] == ''
          nil
        elsif @event.technologies_built_changed?
          @event.technologies_built - @event.technologies_built_was
        else
          @event.technologies_built
        end

      @box =
        if event_params[:boxes_packed] == ''
          nil
        elsif @event.boxes_packed_changed?
          @event.boxes_packed - @event.boxes_packed_was
        else
          @event.boxes_packed
        end

      # AdjustItemCounts.new(@event, @loose, @box) unless @event.inventory.present?
      @inventory_created = 'Inventory created.'

    end

    if @event.start_time_was > Time.now && (@event.start_time_changed? || @event.end_time_changed? || @event.location_id_changed? || @event.technology_id_changed? || @event.is_private_changed?)
      # Can't use delayed_job because ActiveModel::Dirty doesn't persist
      EventMailer.changed(@event, current_user).deliver_now
      @admins_notified = 'Admins notified.'
      if @event.registrations.exists? && (@event.start_time_changed? || @event.end_time_changed? || @event.location_id_changed? || @event.technology_id_changed?)
        @event.registrations.each do |registration|
          # Can't use delayed_job because ActiveModel::Dirty doesn't persist
          RegistrationMailer.event_changed(registration, @event).deliver_now
          @users_notified = 'All registered builders notified.'
        end
      end
    end

    @send_results_emails = false
    # CONDITIONS:
    # This is the first time the event report is being submitted (emails_sent == false)
    # The attendance is above 0
    # There are registrations associated with the event
    # The event generated some loose_count or unopened_boxes_count result
    # The 'Submit Report & Email Results' button was pushed (as opposed to the 'Submit Report' button)
    if @event.emails_sent == false && @event.attendance&.positive? && @event.registrations.count&.positive? && @more_than_zero && params[:send_report].present?
      @send_results_emails = true
      @event.emails_sent = true
      @results_emails_sent = 'Attendees notified of results.'
    end

    if @event.save
      flash[:success] = "Event updated. #{@admins_notified} #{@users_notified} #{@results_emails_sent} #{@inventory_created}"

      @event.registrations.where(attended: true).each do |r|
        RegistrationMailer.delay.event_results(r) if @send_results_emails == true
        KindfulClient.new.import_user_w_note(r)
      end

      redirect_to event_path(@event)
    else
      flash[:danger] = 'There was a problem saving this event report.'
      @show_advanced = true
      render 'edit'
    end
  end

  def destroy
    authorize @event = Event.find(params[:id])

    @event_id = @event.id

    @admins_notified = ''
    @users_notified = ''

    # send emails to registrations and leaders before cancelling
    if @event.start_time > Time.now
      # Send the Event ID instead of the record, since the recod gets pushed out of default scope on paranoid deletion.
      EventMailer.delay.cancelled(@event_id, current_user)
      @admins_notified = 'Admins notified.'

      if @event.registrations.exists?
        # Collect the registration IDs instead of the records, because the records get pushed out of default scope on paranoid deletion.
        @registration_ids = @event.registrations.map(&:id)

        @registration_ids.each do |registration_id|
          RegistrationMailer.delay.event_cancelled(registration_id)
        end
        @users_notified = 'All registered builders notified.'
      end

    end

    if @event.destroy
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

    @finder = 'cancelled'
  end

  def closed
    authorize @closed_events
    @user = current_user

    @finder = 'closed'
  end

  def lead
    @user = current_user
    @events = []

    Event.future.each do |e|
      @events << e if e.needs_leaders?
    end

    authorize @events.first if @events.any?

    @finder = 'lead'
  end

  def leaders
    authorize @event = Event.find(params[:id])

    @leaders = User.leaders
    @already_registered_leaders = User.find(@event.registrations.registered_as_leader.pluck(:user_id))
    @remaining_leaders = @leaders - @already_registered_leaders
  end

  def leader_unregister
    authorize @event = Event.find(params[:id])
    @registration = @event.registrations.registered_as_leader.where(user_id: params[:user_id]).first

    if @registration.blank?
      flash[:error] = 'Oops, something went wrong.'
    else
      @registration.delete
      flash[:success] = "#{@registration.user.name} was unregistered."
    end

    redirect_to leaders_event_path(@event)
  end

  def leader_register
    authorize @event = Event.find(params[:id])
    @registration = @event.registrations.where(user_id: params[:user_id]).first_or_initialize

    @registration.leader = true
    @registration.restore if @registration.deleted?
    @registration.save
    RegistrationMailer.created(@registration).deliver_now

    flash[:success] = "Registered #{@registration.user.name}."
    redirect_to leaders_event_path(@event)
  end

  def restore
    authorize @event = Event.only_deleted.find(params[:id])
    if params[:recursive] == 'false'
      Event.restore(@event.id)
      flash[:success] = 'Event restored but not registrations.'
    else
      Event.restore(@event.id, recursive: true)
      flash[:success] = 'Event and associated registrations restored.'
    end

    if Event.only_deleted.exists?
      redirect_to cancelled_events_path
    else
      redirect_to events_path
    end
  end

  def replicate
    @event = Event.find(params[:id])

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
    @event = Event.find(params[:id])

    replicator = Replicator.new(replicator_params)

    replicator.event_id = @event.id
    replicator.initiator = current_user

    if replicator.go!
      flash[:success] = 'Event was successfully replicated!'
      redirect_to root_path
    else
      flash[:warning] = replicator.errors.messages
      @event = Event.find(params[:id])
      @replicator = Replicator.new
      render :replicate
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
    @tech_img = @technology.display_image
    @location = @event.location
    @location_img = @location.image

    @tech_blurb = @technology.description

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
    @cancelled_events = Event.where.not(discarded_at: nil)
    @closed_events = Event.closed
  end
end
