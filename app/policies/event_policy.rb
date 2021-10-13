# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  attr_reader :user, :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  def create?
    user&.admin_or_leader?
  end

  def destroy?
    create?
  end

  def update?
    create?
  end

  def new?
    create?
  end

  def show?
    if event.in_the_past?
      if user&.is_admin?
        true
      elsif user&.is_leader? && user&.leading?(event)
        # only show it if the leader led the event
        true
      else # anonymous users and builders can't see past events
        false
      end
    else # future events can always be seen by everyone
      true
    end
  end

  def edit?
    create?
  end

  def cancelled?
    create?
  end

  def closed?
    user&.is_admin?
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

  def restore?
    create?
  end

  def messenger?
    create?
  end

  def sender?
    create?
  end

  def attendance?
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
