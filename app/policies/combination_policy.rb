# frozen_string_literal: true

class CombinationPolicy < Struct.new(:user, :combination)
  # attr_reader :user, :technology

  def index?
    user&.admin_or_leader?
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
