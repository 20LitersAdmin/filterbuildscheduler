class RegistrationPolicy < ApplicationPolicy
  attr_reader :user, :registration

  def initialize(user, registration)
    @user = user
    @registration = registration
  end

  def delete?
    user.admin? || registration.user == user
  end

end
