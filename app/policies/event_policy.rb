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
    user&.admin_or_leader?
  end

  def update?
    user&.admin_or_leader?
  end

  def new?
    user&.admin_or_leader?
  end

  def show?
    if event.in_the_past?
      if user.is_admin?
        true
      elsif user.is_leader?
        # only show it if the leader led the event
        if event.registrations.where(user: user).where(leader: true).present?
          true
        else
          false
        end
      else # anonymous users and builders can't see past events
        false
      end
    else # future events can always be seen by everyone
      true
    end
  end

  def edit?
    user&.admin_or_leader?
  end

  def cancelled?
    user&.admin_or_leader?
  end

  def closed?
    user&.is_admin?
  end

  def lead?
    user&.admin_or_leader?
  end

  def restore?
    user&.admin_or_leader?
  end

  def messenger?
    user&.admin_or_leader?
  end

  def sender?
    user&.admin_or_leader?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.is_admin?
        Event.all
      elsif user
        user.available_events
      else
        Event.non_private
      end
    end
  end
end
