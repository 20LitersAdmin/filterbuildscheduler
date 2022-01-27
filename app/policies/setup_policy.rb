# frozen_string_literal: true

class SetupPolicy < ApplicationPolicy
  attr_reader :user, :setup

  def initialize(user, setup)
    @user = user
    @setup = setup
    super
  end

  def new?
    user&.can_manage_setup_crew? || user&.is_setup_crew?
  end

  def create?
    new?
  end

  def edit?
    user&.can_manage_setup_crew?
  end

  def update?
    edit?
  end

  def destroy?
    user&.can_manage_setup_crew?
  end

  def register?
    user&.is_setup_crew?
  end
end
