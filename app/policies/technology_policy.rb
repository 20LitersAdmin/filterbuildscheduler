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
    index?
  end

  def prices?
    index?
  end

  def label?
    index?
  end

  def labels?
    index?
  end

  def labels_select?
    index?
  end

  def donation_list?
    index?
  end
end
