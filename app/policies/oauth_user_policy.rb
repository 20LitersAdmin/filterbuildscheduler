# frozen_string_literal: true

class OauthUserPolicy < ApplicationPolicy
  def in?
    # TODO: users must be oauth_admin to hit this link, but no CRUD for User#is_oauth_admin in RailsAdmin atm.
    user&.is_oauth_admin?
  end

  def index?
    in?
  end

  def callback?
    in?
  end

  def out?
    in?
  end

  def failure?
    in?
  end

  def status?
    in?
  end

  def manual?
    in?
  end

  def update?
    in?
  end
end
