class RegistrationsController < ApplicationController
  before_action :find_registration, only: [:edit, :update, :destroy]

  def create
    waiver_accepted = params[:registration].delete(:waiver_accepted)
    raise ActionController::BadRequest, "must accept waiver to participate" if waiver_accepted == '0'

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
        flash[:success] = "You successfully registered!"
      end
    else
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
        # Make them accept the waiver on their first successful registration, not this
        # failed registration
        current_user.update_attributes!(signed_waiver_on: nil)
        flash[:danger] = reg.errors.first.join(": ")
      else
        RegistrationMailer.delay.created reg
        flash[:success] = "You successfully registered!"
      end
    end

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
end
