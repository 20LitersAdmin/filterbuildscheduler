class RegistrationPolicy < ApplicationPolicy
  def create?
    #user.admin_or_leader? || record.user == user
    true
  end

  def destroy?
    user.admin_or_leader? || record.user == user
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

  def messenger?
    user.admin_or_leader?
  end

  def sender?
    user.admin_or_leader?
  end
end
