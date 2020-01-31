# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def delete?
    user&.is_admin?
  end

  def show?
    user&.is_admin? || user == record
  end

  def update?
    user&.is_admin? || user == record
  end

  def communication?
    user&.is_admin?
  end

  def leaders?
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
