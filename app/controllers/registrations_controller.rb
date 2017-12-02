class RegistrationsController < ApplicationController
  before_action :find_registration, only: [:edit, :update, :destroy]
  before_action :authenticate_user_from_token!, only: [:edit, :update, :destroy]

  def index
    @event = Event.find(params[:event_id])
    @registrations = @event.registrations
  end

  def new
    @event = Event.find(params[:event_id])
    @registration = Registration.new(event_id: @event.id)
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
      @leader = false
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
      if !current_user
        sign_in(:user, @user)
      end
      @leader = false

      @duplicate_registration_risk = true
    end # case params[:registration][:form_source]

    # A user who exists but isn't signed in shouldn't be able to register for an event more than once.
    if @duplicate_registration_risk
      registration = Registration.where(event: @event, user: @user)
      if registration.exists?
        @registration.errors.add(:email, "This email address has already registered for this event.")
      end
    end

    # check for a deleted record before creating a new one.
    if Registration.with_deleted.where(user_id: @user.id, event_id: @event.id).exists?
      @registration = Registration.with_deleted.where(user_id: @user.id, event_id: @event.id).first
      @registration.restore
    else
      @registration = Registration.new(event: @event,
                              user: @user,
                            leader: @leader,
                 guests_registered: params[:registration][:guests_registered],
                    accommodations: params[:registration][:accommodations])
    end

    authorize @registration

    if waiver_accepted == '0'
      @registration.errors.add(:waiver_accepted, "You must review and sign the Liability Waiver first")
    end

    if @event.max_registrations < (@event.total_registered + params[:registration][:guests_registered].to_i + 1) #count up the totals and validate
      @registration.errors.add(:guests_registered, "You can only bring up to #{@event.registrations_remaining - 1} guests at this event.")
    end

    if @registration.errors.any?
      flash[:danger] = @registration.errors.messages.map { |k,v| v }.join(', ')
    else
      @registration.save
      if @event.start_time > Time.now # don't send emails for past events.
        RegistrationMailer.delay.created @registration
        # RegistrationMailer.created(@registration).deliver!
      end
      @user.update_attributes!(signed_waiver_on: Time.now) unless current_user.waiver_accepted
      flash[:success] = "Registration successful!"
    end

    # This is what's needed to use f.error_notification, but how within nested model && with user_params??
    # if @registration.save
    #   if @event.start_time > Time.now # don't send emails for past events.
    #     RegistrationMailer.delay.created @registration
    #     # RegistrationMailer.created(@registration).deliver!
    #   end
    #   @user.update_attributes!(signed_waiver_on: Time.now) unless current_user.waiver_accepted
    #   flash[:success] = "Registration successful!"
    # end

    if params[:registration][:form_source] == "admin"
      redirect_to event_registrations_path @event
    else
      redirect_to event_path @event
    end

  end



  def edit
  end

  def show
  end

  def update
    authorize @registration
    @registration.update(registration_params)
    if @registration.errors.any?
      flash[:danger] = @registration.errors.first.messages.map { |k,v| v }.join(', ')
    end
    redirect_to event_path(@registration.event)
  end

  def destroy
    authorize @registration
    @registration.delete
    flash[:warning] = "You are no longer registered."
    redirect_to event_path(@registration.event)
  end

  private

  def user_params
    params.require(:user).permit(:fname, :lname, :email)
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
