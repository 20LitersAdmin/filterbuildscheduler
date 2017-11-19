class RegistrationPolicy < ApplicationPolicy
  def create?
    record.user == user
  end

  def destroy?
    user.is_admin? || record.user == user
  end

  def update?
    return true if user.is_admin?
    if record.leader
      user.is_leader
    else
      record.user == user
    end
  end

  def index?
    user.admin_or_leader?
  end

  def new?
    user.admin_or_leader?
  end

  def edit?
    user.admin_or_leader?
  end

  def show?
    user.admin_or_leader?
  end
end
