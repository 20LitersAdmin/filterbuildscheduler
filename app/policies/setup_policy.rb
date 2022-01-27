# frozen_string_literal: true

class SetupPolicy < ApplicationPolicy
  attr_reader :user, :setup

  def initialize(user, setup)
    @user = user
    @setup = setup
    super
  end

  def edit?
    user&.can_manage_setup_crew?
  end

  def update?
    edit?
  end
end
