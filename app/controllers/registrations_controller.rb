class RegistrationsController < ApplicationController
  before_action :find_registration, only: [:edit, :update, :destroy]
  before_action :authenticate_user_from_token!, only: [:edit, :update, :destroy]

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
    waiver_accepted = params[:registration].delete(:waiver_accepted)
    @event = Event.find(params[:event_id])

    case params[:registration][:form_source]
      # Admin registering for user      <- find_or_initialize user && save
      # Anon user registering for self  <-- find_or_initialize user && save && signin
      # Current_user self-registering   <-- current_user
    when "admin"
      @user = User.find_or_initialize_by(email: user_params[:email])
      @user.fname ||= user_params[:fname]
      @user.lname ||= user_params[:lname]
      @user.signed_waiver_on ||= Time.now
      @user.save!
      # if !@user.save
      #   render 'edit' and return
      # end
      if @user.can_lead_event?(@event)
        @leader = true
      else
        @leader = false
      end
      @duplicate_registration_risk = false
    when "self"
      @user = current_user
      @leader = params[:registration][:leader] || false
      @duplicate_registration_risk = false
    else # == "anon" or anything else
      @user = User.find_or_initialize_by(email: user_params[:email])
      @user.fname = user_params[:fname]
      @user.lname = user_params[:lname]
      #@user.signed_waiver_on ||= Time.now
      @user.save!
      # if !@user.save
      #   @registration = Registration.new(event: @event)
      #   render 'events/show' and return
      # end
      if !current_user
        sign_in(:user, @user)
      end
      @leader = false

      @duplicate_registration_risk = true
    end # case params[:registration][:form_source]

    # check for a deleted record before creating a new one.
    if Registration.with_deleted.where(user_id: @user.id, event_id: @event.id).exists?
      @registration = Registration.with_deleted.where(user_id: @user.id, event_id: @event.id).first
      @registration.restore
      @registration.guests_registered = registration_params[:guests_registered]
      @registration.accommodations = registration_params[:accommodations]
      @registration.leader = registration_params[:leader] || false
      @registration.save
    else
      @registration = Registration.new(event: @event,
                              user: @user,
                            leader: @leader,
                 guests_registered: params[:registration][:guests_registered],
                    accommodations: params[:registration][:accommodations])
    end

    authorize @registration

    # A user who exists but isn't signed in shouldn't be able to register for an event more than once.
    if @duplicate_registration_risk
      registration = Registration.where(event: @event, user: @user)
      if registration.exists?
        @registration.errors.add(:email, "This email address has already registered for this event.")
      end
    end

    if registration_params[:leader] == "1" && !@user.can_lead_event?(@event)
      @registration.errors.add(:fname, "This user isn't qualified to lead this event.")
    end

    if waiver_accepted == '0'
      @registration.errors.add(:waiver_accepted, "You must review and sign the Liability Waiver first")
    end

    if @event.max_registrations < (@event.total_registered + params[:registration][:guests_registered].to_i + 1) #count up the totals and validate
      @registration.errors.add(:guests_registered, "You can only bring up to #{@event.registrations_remaining - 1} guests at this event.")
    end

    if @registration.errors.any?
      flash[:danger] = @registration.errors.messages.map { |k,v| v }.join(', ')
      if params[:registration][:form_source] == "admin"
        render 'new'
      else
        render 'events/show'
      end
    else
      @registration.save
      if @event.start_time > Time.now # don't send emails for past events.
        RegistrationMailer.delay.created @registration
      end
      @user.update_attributes!(signed_waiver_on: Time.now) unless current_user.waiver_accepted
      flash[:success] = "Registration successful!"

      if params[:registration][:form_source] == "admin"
        redirect_to event_registrations_path @event
      else
        redirect_to event_path @event
      end
    end

    # This is what's needed to use f.error_notification, but how within nested model && with user_params??
    # if @registration.save
    #   if @event.start_time > Time.now # don't send emails for past events.
    #     RegistrationMailer.delay.created @registration
    #   end
    #   @user.update_attributes!(signed_waiver_on: Time.now) unless current_user.waiver_accepted
    #   flash[:success] = "Registration successful!"
    # else
    #   render 'new'
    # end
  end



  def edit
    authorize @registration = Registration.find(params[:id])

    if params[:admin] == "true"
      @btn_admin = true
    else
      @btn_admin = false
    end
  end

  def update
    authorize @registration
    

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
      params.require(:user).permit(:fname, :lname, :email)
    else
      params[:registration].require(:user).permit(:fname, :lname, :email)
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

  private

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user_email = params[:user_email].presence
    user = user_token && user_email && User.find_by_email(user_email.to_s)

    if user && Devise.secure_compare(user.authentication_token, params[:user_token])
      sign_in user
    end
  end
end
