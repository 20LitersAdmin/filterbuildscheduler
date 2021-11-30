# frozen_string_literal: true

class RegistrationsController < ApplicationController
  before_action :find_event
  before_action :find_and_authorize_registration, only: %i[edit update destroy reconfirm restore]

  def index
    authorize @registrations = @event.registrations.active.builders
    @leaders = @event.registrations.active.leaders

    # includes leaders and builders
    @discarded_registrations = @event.registrations.discarded
  end

  def new
    # This endpoint is only used by admins to register builders manually
    # thus, user is always new
    @user = User.new
    authorize @registration = @event.registrations.new
  end

  def create
    waiver_accepted = params[:registration].delete(:accept_waiver)

    case params[:registration][:form_source]
    when 'admin'
      @user = find_or_initialize_user(user_params)
      @user.signed_waiver_on ||= Time.now

      @leader = @user.can_lead_event?(@event)
      @duplicate_registration_risk = true

      if @event.registrations_filled?
        guests = registration_params[:guests_registered].present? ? registration_params[:guests_registered].to_i : 0
        new_max = @event.total_registered + guests + 1
        @event.update(max_registrations: new_max)
      end
    when 'self'
      @user = current_user
      @leader = params[:registration][:leader] || false
      @duplicate_registration_risk = false
    else # 'anon'
      @user = find_or_initialize_user(user_params)
      @leader = false
      @duplicate_registration_risk = true
    end

    @registration = find_or_initialize_registration(@user, @event)
    @registration.assign_attributes(registration_params)

    # A user who exists but isn't signed in shouldn't be able to register for an event more than once.
    if @duplicate_registration_risk
      registration = Registration.where(event: @event, user: @user)
      @user.errors.add(:email, 'This email address has already registered for this event.') if registration.any?
    end

    @user.errors.add(:fname, 'This user isn\'t qualified to lead this event.') if registration_params[:leader] == '1' && !@leader

    @registration.errors.add(:accept_waiver, 'You must review and sign the Liability Waiver first') if waiver_accepted == '0' && @user.signed_waiver_on.blank?

    @registration.errors.add(:guests_registered, "There is only room for #{[@event.registrations_remaining - 1, 0].max} additional guests at this event.") if @event.registrations_would_overflow?(@registration)

    # @registration.save doesn't fail with manually added errors.
    if @registration.errors.none? && @user.save
      @registration.save
      sign_in(@user) unless current_user

      # don't send emails for past events.
      RegistrationMailer.created(@registration).deliver_later if @event.in_the_future?

      @user.update_columns(signed_waiver_on: Date.today) if @user.signed_waiver_on.blank? && waiver_accepted == '1'
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
      # errors found
      flash[:danger] = @registration.errors.messages.map { |_k, v| v }
                                    .join(', ')
      flash[:danger] += @user.errors.messages.map { |k, v| "#{User.human_attribute_name(k)} #{v.join(', ')}" }
                             .join(' | ')

      if params[:registration][:form_source] == 'admin'
        render 'new'
      else
        render 'events/show'
      end
    end
  end

  def edit
    @user = @registration.user

    @btn_admin = params[:admin] == 'true'
  end

  def update
    @user = @registration.user

    authenticate_user_from_token! if params[:user_token].present?

    @registration.assign_attributes(registration_params)

    if @event.registrations_would_overflow?(@registration)

      # Admins can override @event.max_registrations
      if registration_params[:form_source] == 'admin'
        guests = registration_params[:guests_registered].presence&.to_i || 0

        # since @registration is being updated, we need to ignore any previous @registration.guests_registered value
        new_max = @event.total_registered_without(@registration) + guests + 1

        @event.update_columns(max_registrations: new_max)
      else
        # since @registration is being updated, we need to ignore any previous @registration.guests_registered value
        @registration.errors.add(:guests_registered, "There is only room for #{[@event.registrations_remaining_without(@registration) - 1, 0].max} additional guests at this event.")
      end
    end

    @user.update(email_opt_out: user_params[:email_opt_out]) if ActiveModel::Type::Boolean.new.cast(user_params[:email_opt_out]) != @user.email_opt_out

    # @registration.update(registration_params) doesn't fail with manually added errors.
    if @registration.errors.none?
      @registration.save
      if params[:registration][:form_source] == 'admin'
        redirect_to event_registrations_path(@registration.event)
      else
        redirect_to event_path(@registration.event)
      end
    else
      flash[:danger] = @registration.errors
                                    .map { |_k, v| v }
                                    .join(', ')
      @user = @registration.user
      @btn_admin = current_user.is_admin?

      render 'edit'
    end
  end

  def destroy
    @registration.discard
    if params[:admin] == 'true'
      flash[:warning] = 'Registration discarded, but can be restored.'
      redirect_to event_registrations_path(@registration.event)
    else
      flash[:warning] = 'You are no longer registered.'
      redirect_to event_path(@registration.event)
    end
  end

  def restore
    @registration.undiscard

    flash[:success] = 'Registration restored!'
    redirect_to event_registrations_path(@event)
  end

  def restore_all
    @count = @event.registrations.discarded.count

    @event.registrations.discarded.each(&:undiscard)

    flash[:success] = "#{view_context.pluralize(@count, 'discarded registration')} restored!"
    redirect_to event_registrations_path(@event)
  end

  def messenger
    authorize @event
  end

  def sender
    authorize @event
    @subject = params[:subject]
    @message = params[:message]
    @sender = current_user
    @event.registrations.each do |registration|
      EventMailer.messenger(registration, @subject, @message, @sender).deliver_later
    end
    EventMailer.messenger_reporter(@event, @subject, @message, @sender).deliver_later

    flash[:success] = 'Message sent!'
    redirect_to event_registrations_path(@event)
  end

  # re-send all registrations confirmation emails
  def reconfirms
    @event.registrations.each do |registration|
      RegistrationMailer.created(registration).deliver_later
    end
    flash[:success] = "Sending confirmation emails to #{@event.registrations.size} registrants"
    redirect_to event_registrations_path(@event)
  end

  # re-send single registration confirmation email
  def reconfirm
    RegistrationMailer.created(@registration).deliver_now
    flash[:success] = "Re-sent confirmation to #{@registration.user.name}"
    redirect_to event_registrations_path(@event)
  end

  private

  def user_params
    params[:registration].require(:user).permit(
      :fname,
      :lname,
      :email,
      :phone,
      :email_opt_out
    )
  end

  def registration_params
    params.require(:registration).permit(
      :event_id,
      :user_id,
      :leader,
      :guests_registered,
      :accommodations
    )
  end

  def find_event
    @event = Event.active.find(params[:event_id])
  end

  def find_and_authorize_registration
    authorize @registration = Registration.find(params[:id])
  end

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user_email = params[:user_email].presence
    user = user_token && user_email && User.find_by_email(user_email.to_s)

    sign_in user if user && Devise.secure_compare(user.authentication_token, params[:user_token])
  end

  def find_or_initialize_user(data)
    user = User.find_or_initialize_by(email: data[:email])
    user.fname ||= data[:fname]
    user.lname ||= data[:lname]
    user.phone ||= data[:phone]
    # If the user hasn't been opted out, allow the form to opt them out
    # But, if the user has been opted out, don't allow the form to opt them back in
    user.email_opt_out = user.email_opt_out == false && data[:email_opt_out] == '1'

    user
  end

  def find_or_initialize_registration(user, event)
    # check for a discarded record before creating a new one.
    registration_check = Registration.where(user: user, event: event)
    if registration_check.exists?
      registration = registration_check.first
      registration.undiscard
    else
      registration = Registration.new(event: event, user: user)
    end

    registration
  end
end
