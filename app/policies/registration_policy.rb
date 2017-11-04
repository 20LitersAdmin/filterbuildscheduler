class RegistrationPolicy < ApplicationPolicy
  attr_reader :user, :registration

  def initialize(user, registration)
    @user = user
    @registration = registration
  end

  def destroy?
    user.is_admin? || registration.user == user
  end

  def update?
    return true if user.is_admin?
    if registration.leader
      user.is_leader
    else
      registration.user == user
    end
  end
end
