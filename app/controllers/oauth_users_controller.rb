# frozen_string_literal: true

class OauthUsersController < ApplicationController
  before_action :find_and_authorize_user, only: %i[status manual update]

  def in
    if session[:oauth_user_id].present?
      flash[:notice] = 'Already authenticated.'
      redirect_to auth_status_path(session[:oauth_user_id])
    end
  end

  def callback
    auth = request.env['omniauth.auth']

    oauth_user = OauthUser.from_omniauth(auth)
    session[:oauth_user_id] = oauth_user.id

    flash[:notice] = 'Successful authentication!'
    redirect_to auth_status_path(oauth_user.id)
  end

  def out
    session[:oauth_user_id] = nil

    flash[:notice] = 'Signed out of Oauth connection'
    redirect_to auth_in_path
  end

  def failure
    flash[:alert] = "Authentication error: #{params[:message].humanize}"
    redirect_to in_path
  end

  def status
    @emails = @oauth_user.emails
  end

  def manual
    @emails = @oauth_user.emails
  end

  def update
    @oauth_user.update(oauth_user_params)

    if oauth_user_params[:manual_query].present?
      begin
        GmailClient.new(@oauth_user).delay.batch_get_queried_messages(query: oauth_user_params[:manual_query])

      rescue Signet::AuthorizationError => e
        byebug
      end

      respond_to do |format|
        format.js { render 'querying' }
      end
    else
      respond_to do |format|
        format.js {}
      end
    end

  end

  private

  def find_and_authorize_user
    authorize @oauth_user = OauthUser.find(params[:id])
  end

  def oauth_user_params
    params.require(:oauth_user).permit(:sync_emails, :manual_query, :source)
  end
end
