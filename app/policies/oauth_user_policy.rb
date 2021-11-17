# frozen_string_literal: true

class OauthUserPolicy < ApplicationPolicy
  def in?
    # any logged-in user with a matching email domain can see
    Constants::Email::INTERNAL_DOMAINS.include?(user&.email_domain)
  end

  def index?
    # only User#is_oauth_admin? can see
    user&.is_oauth_admin?
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
    # only User#is_oauth_admin? can see
    index?
  end

  def update?
    in?
  end
end
