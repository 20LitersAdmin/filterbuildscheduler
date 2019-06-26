# frozen_string_literal: true

class TechnologyPolicy
  attr_reader :user, :technology

  def initialize(user, technology)
    @user = user
    @technology = technology
  end

  def index?
    user&.can_do_inventory?
  end

  def items?
    user&.can_do_inventory?
  end
end
