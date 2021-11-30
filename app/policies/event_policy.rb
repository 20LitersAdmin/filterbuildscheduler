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
    user&.can_edit_events?
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
    user&.can_manage_leaders?
  end

  def leader_unregister?
    leaders?
  end

  def leader_register?
    leaders?
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

  def replicate?
    create?
  end

  def replicator?
    create?
  end

  def show?
    if event.in_the_past?
      if user&.can_edit_events?
        true
      else
        # anonymous users and builders can't see past events
        false
      end
    else
      # future events can always be seen by everyone
      true
    end
  end

  def sender?
    create?
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
