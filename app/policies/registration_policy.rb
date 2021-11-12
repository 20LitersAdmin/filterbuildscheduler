# frozen_string_literal: true

class RegistrationPolicy < ApplicationPolicy
  attr_reader :user, :registration

  def initialize(user, registration)
    super
    @user = user
    @registration = registration
  end

  def create?
    true
  end

  def destroy?
    edit?
  end

  def restore?
    new?
  end

  def update?
    edit?
  end

  def index?
    new?
  end

  def new?
    user&.admin_or_leader?
  end

  def edit?
    user&.admin_or_leader? || registration.user == user
  end

  def show?
    new?
  end
end
