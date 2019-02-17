# frozen_string_literal: true

class RegistrationsController < ApplicationController
  before_action :find_registration, only: [:edit, :update, :destroy]

  def index
    @event = Event.find(params[:event_id])
    authorize @registrations = @event.registrations.non_leader
    @leaders = @event.registrations.registered_as_leader
    @deleted = @event.registrations.only_deleted
  end

  def new
    @event = Event.find(params[:event_id])
    authorize @registration = Registration.new(event_id: @event.id)
  end

  def create
    waiver_accepted = params[:registration].delete(:accept_waiver)
    @event = Event.find(params[:event_id])

    case params[:registration][:form_source]
    when 'admin'
      @user = find_or_initialize_user(user_params)
      @user.signed_waiver_on ||= Time.now

      @leader = @user.can_lead_event?(@event)
      @duplicate_registration_risk = false

      if @event.registrations_filled?
        guests = registration_params[:guests_registered].present? ? registration_params[:guests_registered].to_i : 0
        new_max = @event.total_registered + guests + 1
        @event.update(max_registrations: new_max)
      end
    when 'self'
      @user = current_user
      @leader = params[:registration][:leader] || false
      @duplicate_registration_risk = false
    else
      @user = find_or_initialize_user(user_params)
      @leader = false
      @duplicate_registration_risk = true
    end

    @registration = find_or_initialize_registration(@user, @event)
    @registration.assign_attributes(registration_params)

    # A user who exists but isn't signed in shouldn't be able to register for an event more than once.
    if @duplicate_registration_risk
      registration = Registration.where(event: @event, user: @user)
      @registration.errors.add(:email, 'This email address has already registered for this event.') if registration.exists?
    end

    @registration.errors.add(:fname, 'This user isn\'t qualified to lead this event.') if registration_params[:leader] == '1' && !@user.can_lead_event?(@event)

    @registration.errors.add(:accept_waiver, 'You must review and sign the Liability Waiver first') if waiver_accepted == '0'

    # count up the totals and validate
    @registration.errors.add(:guests_registered, "You can only bring up to #{@event.registrations_remaining - 1} guests at this event.") if @event.max_registrations < (@event.total_registered + params[:registration][:guests_registered].to_i + 1)

    if @registration.errors.blank? && @user.save && @registration.save
      sign_in(@user) unless current_user

      RegistrationMailer.delay.created(@registration) if @event.start_time > Time.now # don't send emails for past events.

      @user.update_attributes!(signed_waiver_on: Time.now) unless @registration.waiver_accepted?
      flash[:success] = 'Registration successful!'

      if params[:registration][:form_source] == 'admin'
        if params[:commit_and_new].present?
          redirect_to new_event_registration_path @event
        else
          redirect_to event_registrations_path @event
        end
      else
        redirect_to event_path @event
      end
    else
      flash[:danger] = @registration.errors.messages.map { |_k, v| v }.join(', ')
      flash[:danger] += @user.errors.messages.map { |k, v| "#{k} #{v.join(', ')}" }.join(' | ')
      if params[:registration][:form_source] == 'admin'
        render 'new'
      else
        render 'events/show'
      end
    end
  end

  def edit
    authorize @registration

    @btn_admin = params[:admin] == 'true'
  end

  def update
    authorize @registration

    if @registration.event.registrations_filled?
      guests = registration_params[:guests_registered].present? ? registration_params[:guests_registered].to_i : 0
      new_max = @registration.event.total_registered + guests + 1
      @registration.event.update(max_registrations: new_max)
    end

    if @registration.errors.any?
      flash[:danger] = @registration.errors.map { |k,v| v }.join(', ')
      render 'edit'
    else
      @registration.update(registration_params)
      if params[:registration][:form_source] == "admin"
        redirect_to event_registrations_path(@registration.event)
      else
        redirect_to event_path(@registration.event)
      end
    end
  end

  def destroy
    authorize @registration
    @registration.delete
    if params[:admin] == "true"
      flash[:warning] = "Registration deleted."
      redirect_to event_registrations_path(@registration.event)
    else
      flash[:warning] = "You are no longer registered."
      redirect_to event_path(@registration.event)
    end
  end

  def restore
    @event = Event.find(params[:event_id])

    @count = @event.registrations.only_deleted.count

    @event.registrations.only_deleted.each do |r|
      r.restore
      r.save
    end

    flash[:success] = "#{view_context.pluralize(@count, "deleted registration")} restored!"
    redirect_to event_registrations_path(@event)
  end

  def messenger
    authorize @event = Event.find(params[:event_id])
  end

  def sender
    authorize @event = Event.find(params[:event_id])
    @subject = params[:subject]
    @message = params[:message]
    @sender = current_user
    @event.registrations.each do |registration|
      EventMailer.delay.messenger(registration, @subject, @message, @sender)
    end
    EventMailer.delay.messenger_reporter(@event, @subject, @message, @sender)

    flash[:success] = "Message sent!"
    redirect_to event_registrations_path(@event)
  end

  private

  def user_params
    # If the form comes from Event#show, the user is nested in the params.
    if params[:registration][:form_source] == "admin"
      params.require(:user).permit(:fname,
                                    :lname,
                                    :email,
                                    :phone,
                                    :email_opt_out)
    else
      params[:registration].require(:user).permit(:fname,
                                                  :lname,
                                                  :email,
                                                  :phone,
                                                  :email_opt_out)
    end
  end

  def registration_params
    params.require(:registration).permit(:event_id,
                                         :user_id,
                                         :leader,
                                         :guests_registered,
                                         :accommodations)
  end

  def find_registration
    @registration = Registration.find(params[:id])
  end

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user_email = params[:user_email].presence
    user = user_token && user_email && User.find_by_email(user_email.to_s)

    if user && Devise.secure_compare(user.authentication_token, params[:user_token])
      sign_in user
    end
  end

  def find_or_initialize_user(data)
    user = User.find_or_initialize_by(email: data[:email])
    user.fname ||= data[:fname]
    user.lname ||= data[:lname]
    user.phone ||= data[:phone]
    # If the user hasn't been opted out, allow the form to opt them out
    # But, if the user has been opted out, don't allow the form to opt them back in
    if user.email_opt_out == false && data[:email_opt_out] == "1"
      user.email_opt_out = true
    end

    user
  end

  def find_or_initialize_registration(user, event)
    # check for a deleted record before creating a new one.
    registration_check = Registration.with_deleted.where(user: user, event: event)
    if registration_check.exists?
      registration = registration_check.first
      registration.restore
    else
      registration = Registration.new(event: event, user: user)
    end

    registration
  end
end
