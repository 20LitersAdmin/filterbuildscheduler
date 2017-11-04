
class TechnologyPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def initialize(user, technology)
    @user = user
    @technology = technology
  end

  def delete?
    user.admin?
  end

end
