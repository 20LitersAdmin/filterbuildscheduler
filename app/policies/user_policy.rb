class UserPolicy < ApplicationPolicy

  def delete?
    user.is_admin?
  end

  def show?
    if user.present?
      user.is_admin? || user == record
    else
      false
    end
  end

  def update?
    user.is_admin? || user == record
  end

  def communication?
    user.is_admin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.is_leader? || user&.is_admin?
        User.all
      elsif user
        user
      end
    end
  end

end
