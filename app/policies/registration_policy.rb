class RegistrationPolicy < ApplicationPolicy
  attr_reader :user, :registration

  def initialize(user, registration)
    @user = user
    @registration = registration
  end

  def create?
    true
  end

  def destroy?
    user&.admin_or_leader? || registration.user == user
  end

  def update?
    user&.admin_or_leader? || registration.user == user
  end

  def index?
    user&.admin_or_leader?
  end

  def new?
    user&.admin_or_leader?
  end

  def edit?
    user&.admin_or_leader? || registration.user == user
  end

  def show?
    user&.admin_or_leader?
  end
end
