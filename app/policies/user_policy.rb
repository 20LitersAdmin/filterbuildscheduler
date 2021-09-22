# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def delete?
    user&.is_admin?
  end

  def show?
    user&.is_admin? || user == record
  end

  def update?
    show?
  end

  def communication?
    delete?
  end

  def leaders?
    delete?
  end

  def availability?
    delete?
  end

  def leader_type?
    delete?
  end

  def edit_leader_notes?
    delete?
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
