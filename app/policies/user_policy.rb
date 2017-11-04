
class UserPolicy < ApplicationPolicy
  attr_reader :user, :recipient

  def initialize(user, recipient)
    @user = user
    @recipient = recipient
  end

  def delete?
    user.admin?
  end

end
