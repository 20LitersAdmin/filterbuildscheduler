# frozen_string_literal: true

class OauthUsersController < ApplicationController
  before_action :find_and_authorize_user, only: %i[status show manual update delete]

  layout 'blank', only: [:update]

  def in
    return unless session[:oauth_user_id].present?

    flash[:notice] = 'Already authenticated.'
    redirect_to auth_status_path(session[:oauth_user_id])
  end

  def index
    authorize @oauth_users = OauthUser.ordered_by_id
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
    @emails = @oauth_user.emails.ordered
  end

  def show
    redirect_to auth_status_path(@oauth_user)
  end

  def manual
    @emails = @oauth_user.emails.synced.ordered
  end

  def update
    # from #manual:
    #   can submit :manual_query
    # from #status
    #   can submit :sync_emails
    @oauth_user.update(oauth_user_params)

    if oauth_user_params[:manual_query].present?
      begin
        GmailClient.new(@oauth_user).batch_get_queried_messages(query: oauth_user_params[:manual_query])
      rescue Signet::AuthorizationError => e
        @error = e
      end

      if @error
        respond_to do |format|
          format.js { render 'error', layout: false }
        end
      else
        respond_to do |format|
          format.js { render 'querying', layout: false }
        end
      end
    else
      respond_to do |format|
        format.js { render 'update', layout: false }
      end
    end
  end

  def delete
    @oauth_user.destroy

    flash[:notice] = 'Deleted Oauth User and associated emails.'
    redirect_to auth_index_path
  end

  private

  def find_and_authorize_user
    authorize @oauth_user = OauthUser.find(params[:id])
  end

  def oauth_user_params
    params.require(:oauth_user).permit(:sync_emails, :manual_query, :source)
  end
end
