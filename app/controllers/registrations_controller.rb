class RegistrationsController < ApplicationController
  before_action :find_registration, only: [:edit, :update, :destroy]
  before_action :authenticate_user_from_token!, only: [:edit, :update, :destroy]

  def create
    waiver_accepted = params[:registration].delete(:waiver_accepted)
    @event = Event.find(params[:event_id])

    #raise ActionController::BadRequest, "must accept waiver to participate" if waiver_accepted == '0'
    if waiver_accepted == '0'
      flash[:danger] = "You must review and sign the Liability Waiver first"
    elsif @event.max_registrations < (@event.total_registered + params[:registration][:guests_registered].to_i + 1) #count up the totals and validate
      # This should be handled by Registration.under_max_registrations?
      flash[:danger] = "There is only room for #{@event.registrations_remaining - 1} guests at this event."
    else
      if current_user
        reg = Registration.new(event_id: params[:event_id],
                                   user: current_user,
                                   leader: params.dig(:registration, :leader),
                                   guests_registered: params[:registration][:guests_registered])
        authorize reg
        reg.save

        if reg.errors.any?
          flash[:danger] = reg.errors.first.join(": ")
        else
          current_user.update_attributes!(signed_waiver_on: Time.now) unless current_user.waiver_accepted
          RegistrationMailer.delay.created reg
          # RegistrationMailer.created(reg).deliver!
          flash[:success] = "You successfully registered!"
        end
      else # anonymous user
        user = User.find_or_initialize_by(email: user_params[:email]) do |user|
          user.fname = user_params[:fname]
          user.lname = user_params[:lname]
          user.signed_waiver_on = Time.now
        end

        user.save! && sign_in(:user, user) if user.new_record?

        reg = Registration.new(event_id: params[:event_id],
                                   user_id: user.id,
                                   accommodations: params.dig(:registration, :accommodations),
                                   guests_registered: params[:registration][:guests_registered])

        authorize reg
        reg.save

        if reg.errors.any?
          # Make anonymous users accept the waiver on their first successful registration, not this
          # failed registration
          current_user.update_attributes!(signed_waiver_on: nil)
          flash[:danger] = reg.errors.first.join(": ")
        else
          RegistrationMailer.delay.created reg
          # RegistrationMailer.created(reg).deliver!
          flash[:success] = "You successfully registered!"
        end
      end # if current_user

    end # if waiver_accepted == '0'

    redirect_to event_path params[:event_id]
  end

  def edit
  end

  def update
    authorize @registration
    @registration.update(registration_params)
    if @registration.errors.any?
      flash[:danger] = @registration.errors.first.join(": ")
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
