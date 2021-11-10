# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  attr_reader :user, :event

  def initialize(user, event)
    @user = user
    @event = event
    super
  end

  def attendance?
    create?
  end

  def create?
    user&.admin_or_leader?
  end

  def destroy?
    create?
  end

  def edit?
    create?
  end

  def lead?
    create?
  end

  def leaders?
    closed?
  end

  def leader_unregister?
    closed?
  end

  def leader_register?
    closed?
  end

  def messenger?
    create?
  end

  def new?
    create?
  end

  def poster?
    show?
  end

  def show?
    if event.in_the_past?
      if user&.is_admin? ||
         (user&.is_leader? && user&.leading?(event))

        # only show it if the leader led the event
        true
      else # anonymous users and builders can't see past events
        false
      end
    else # future events can always be seen by everyone
      true
    end
  end

  def update?
    create?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user
        user.available_events
      else
        Event.non_private
      end
    end
  end
end
