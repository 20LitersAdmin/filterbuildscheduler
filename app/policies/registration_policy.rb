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
end
