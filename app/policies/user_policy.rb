# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def delete?
    user&.is_admin?
  end

  def show?
    user&.can_manage_users? || user == record
  end

  def update?
    show?
  end

  def communication?
    update?
  end

  def comm_update?
    update?
  end

  def leaders?
    user&.can_manage_leaders?
  end

  def availability?
    leaders?
  end

  def leader_type?
    leaders?
  end

  def edit_leader_notes?
    leaders?
  end

  def edit?
    show?
  end

  def admin_password_reset?
    user&.is_admin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.admin_or_leader?
        User.all
      elsif user
        user
      end
    end
  end
end
