class UserPolicy < ApplicationPolicy
  def delete?
    user.admin?
  end

  def update?
    user.is_admin? || user == record
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
