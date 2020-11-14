# frozen_string_literal: true

class OauthUserPolicy < ApplicationPolicy
  def in?
    user&.is_admin?
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
