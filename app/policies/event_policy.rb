class EventPolicy < ApplicationPolicy
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
    true
  end

  def edit?
    user&.admin_or_leader?
  end

  def cancelled?
    user&.is_admin?
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
      if user&.is_leader? || user&.is_admin?
        Event.all
      elsif user
        user.available_events
      else
        Event.non_private
      end
    end
  end
end
