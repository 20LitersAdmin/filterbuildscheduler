class EventPolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if @user&.is_leader? || @user&.is_admin?
        Event.all
      elsif @user
        @user.available_events
      else
        Event.non_private
      end
    end
  end

  def delete?
    user.admin?
  end
end
