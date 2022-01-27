# frozen_string_literal: true

class SetupPolicy < ApplicationPolicy
  attr_reader :user, :setup

  def initialize(user, setup)
    @user = user
    @setup = setup
    super
  end

  def new?
    user&.can_view_setup?
  end

  def create?
    new?
  end

  def edit?
    user&.can_manage_users?
  end

  def update?
    edit?
  end

  def destroy?
    user&.can_manage_users?
  end

  def register?
    user&.can_view_setup?
  end
end
