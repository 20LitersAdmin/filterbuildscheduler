# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :find_and_authorize_user, only: %i[show edit update delete availability leader_type edit_leader_notes comm_update admin_password_reset]

  def show
    flash[:warning] = 'You haven\'t set your password yet, please do so now.' if @user.has_no_password

    @leading_events = @user.registrations
                           .kept
                           .where(leader: true)
                           .joins(:event)
                           .where('events.end_time > ?', Time.now)
                           .map(&:event)

    @attending_events = @user.registrations
                             .kept
                             .where(leader: false)
                             .joins(:event)
                             .where('events.end_time > ?', Time.now)
                             .map(&:event)

    @lead_events = @user.registrations
                        .kept
                        .where(leader: true)
                        .joins(:event)
                        .where('events.end_time < ?', Time.now)
                        .map(&:event)

    @attended_events = @user.registrations
                            .kept
                            .where(leader: false)
                            .joins(:event)
                            .where('events.end_time < ?', Time.now)
                            .map(&:event)
  end

  def edit
    flash[:warning] = 'You haven\'t set your password yet, please do so now.' if @user.has_no_password
  end

  def edit_leader_notes
    respond_to do |format|
      format.js { render 'edit_leader_notes', layout: 'blank' }
    end
  end

  def update
    modified_params = params[:user][:password].blank? && params[:user][:password_confirmation].blank? ? user_params_no_pws : user_params

    if @user.update(modified_params)
      respond_to do |format|
        format.html do
          flash[:success] = 'Info updated!'

          if modified_params[:password].present?
            DeviseMailer.password_change(@user).deliver_now
            sign_out @user
          end

          redirect_to show_user_path @user
        end
        # from `/leaders` updating leader_notes
        format.js { render 'update', layout: 'blank' }
      end
    else
      respond_to do |format|
        format.html { render 'edit' }
        format.js { head 500 }
      end
    end
  end

  def delete
    @user.delete
    flash[:danger] = 'User deleted'
    redirect_to users_path
  end

  def communication
    # filter out users with no registrations by joining :registrations
    authorize @users = User.builders.joins(:registrations).group('users.id').order('users.created_at DESC')
  end

  def comm_update
    # When being unchecked, no param is submitted
    # When being checked, param is submitted as "1"
    # #<ActionController::Parameters {"email_opt_out"=>"true" ...
    box_was_checked = params[:email_opt_out].present?

    # update @user.email_opt_out unless they already match
    @user.update_columns(email_opt_out: box_was_checked) unless box_was_checked == @user.email_opt_out?

    head :ok
  end

  def leaders
    @contactor = Contactor.new(contactor_params)

    authorize @leaders = @contactor.user_ids.any? ? User.leaders.where(id: @contactor.user_ids) : User.leaders

    @contact_size = @leaders.size

    @availability = [['All hours', 0], ['Business hours', 1], ['After hours', 2]]
    @types = [['', nil], ['Trainee', 0], ['Helper', 1], ['Primary', 2]]
    @technologies = [['All', 0]]
    Technology.list_worthy.each do |tech|
      @technologies << [tech.short_name, tech.id]
    end

    @cancelled_events = Event.discarded
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

  def admin_password_reset
    # custom RailsAdmin link on admin/user/:id/edit hits this action
    @user.send_reset_password_instructions

    flash[:success] = 'Password reset email sent!'
    redirect_to request.referrer
  end

  def leader_type
    # users/:id/leader_type?t=[0,1,2,99]
    # [['', nil][trainee, 0], [helper, 1], [primary, 2]]
    hsh = User.leader_types.dup

    t = params[:t].blank? ? nil : params[:t].to_i

    @user.update(leader_type: t) if hsh.values.include?(t) || t.nil?

    render json: User.leader_types[@user.reload.leader_type]
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
                                 :leader_notes,
                                 :password,
                                 :password_confirmation
  end

  def user_params_no_pws
    params.require(:user).permit :fname,
                                 :lname,
                                 :email,
                                 :phone,
                                 :email_opt_out,
                                 :leader_notes
  end

  def contactor_params
    if params['contactor'].present?
      params.require(:contactor).permit :availability,
                                        :technology
    end
  end
end
