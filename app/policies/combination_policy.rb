# frozen_string_literal: true

class CombinationPolicy < Struct.new(:user, :combination)
  # attr_reader :user, :technology

  def show?
    user&.admin_or_leader?
  end

  def edit?
    show?
  end

  def price?
    show?
  end

  def item_search?
    show?
  end
end
