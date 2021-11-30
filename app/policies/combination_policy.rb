# frozen_string_literal: true

class CombinationPolicy < Struct.new(:user, :combination)
  # attr_reader :user, :technology

  def index?
    user&.can_do_inventory?
  end

  def show?
    index?
  end

  def edit?
    index?
  end

  def price?
    index?
  end

  def item_search?
    index?
  end
end
