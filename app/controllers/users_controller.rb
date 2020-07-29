# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :find_and_authorize_user, only: %i[show edit update delete availability]

  def show
    flash[:warning] = 'You haven\'t set your password yet, please do so now.' if @user.has_no_password

    @leading_events = @user.registrations
                           .where(leader: true)
                           .joins(:event)
                           .where('events.end_time > ?', Time.now)
                           .map(&:event)
    @attending_events = @user.registrations
                             .where(leader: false)
                             .joins(:event)
                             .where('events.end_time > ?', Time.now)
                             .map(&:event)
    @lead_events = @user.registrations
                        .where(leader: true)
                        .joins(:event)
                        .where('events.end_time < ?', Time.now)
                        .map(&:event)
    @attended_events = @user.registrations
                            .where(leader: false)
                            .joins(:event)
                            .where('events.end_time < ?', Time.now)
                            .map(&:event)
  end

  def edit
    flash[:warning] = 'You haven\'t set your password yet, please do so now.' if @user.has_no_password
  end

  def update
    modified_params = params[:user][:password].blank? && params[:user][:password_confirmation].blank? ? user_params_no_pws : user_params

    if @user.update(modified_params)
      flash[:success] = 'Info updated!'

      if modified_params[:password].present?
        DeviseMailer.password_change(@user).deliver_now
        sign_out @user
      end

      redirect_to show_user_path @user
    else
      render 'edit'
    end
  end

  def delete
    @user.delete
    flash[:danger] = 'User deleted'
    redirect_to users_path
  end

  def communication
    # filter out users with no registrations by joining
    authorize @users = User.builders.joins(:registrations).group('users.id').order('users.created_at DESC')

    @cancelled_events = Event.only_deleted
    @closed_events = Event.closed

    @finder = 'communication'
  end

  def comm_complete
    @user_ids = params[:user_ids]

    if @user_ids.present?
      User.find(@user_ids).each do |u|
        u.email_opt_out = true
        u.save
      end
    end

    redirect_to users_communication_path
  end

  def leaders
    @contactor = Contactor.new(contactor_params)

    authorize @leaders = @contactor.user_ids.any? ? User.leaders.where(id: @contactor.user_ids) : User.leaders

    @contact_size = @leaders.size

    @availability = [['All hours', 0], ['Business hours', 1], ['After-hours', 2]]
    @technologies = [['All', 0]]
    Technology.list_worthy.each do |tech|
      @technologies << [tech.short_name, tech.id]
    end

    @finder = 'leaders'
    @cancelled_events = Event.only_deleted
    @closed_events = Event.closed
  end

  def availability
    # users/:id/availability?a=[0,1,2]
    # [['All hours', 0], ['Business hours', 1], ['After-hours', 2]]
    case params[:a]
    when '0'
      @user.update(available_business_hours: true, available_after_hours: true)
    when '1'
      @user.update(available_business_hours: true, available_after_hours: false)
    when '2'
      @user.update(available_business_hours: false, available_after_hours: true)
    end

    render json: @user.reload.availability_code
  end

  private

  def find_and_authorize_user
    authorize @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit :fname,
                                 :lname,
                                 :email,
                                 :phone,
                                 :email_opt_out,
                                 :password,
                                 :password_confirmation
  end

  def user_params_no_pws
    params.require(:user).permit :fname,
                                 :lname,
                                 :email,
                                 :phone,
                                 :email_opt_out
  end

  def contactor_params
    if params['contactor'].present?
      params.require(:contactor).permit :availability,
                                        :technology
    end
  end
end
