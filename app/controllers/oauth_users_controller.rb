# frozen_string_literal: true

class OauthUsersController < ApplicationController
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
    @oauth_user = OauthUser.find(params[:id])
  end
end
