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

  def edit?
    user&.can_edit_events? || registration.user == user
  end

  def index?
    new?
  end

  def messenger?
    new?
  end

  def new?
    user&.can_edit_events?
  end

  def reconfirm?
    new?
  end

  def reconfirms?
    new?
  end

  def restore?
    new?
  end

  def restore_all?
    new?
  end

  def sender?
    new?
  end

  def show?
    edit?
  end

  def update?
    edit?
  end
end
