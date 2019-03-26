# frozen_string_literal: true

class InventoryPolicy
  attr_reader :user, :inventory

  def initialize(user, inventory)
    @user = user
    @inventory = inventory
  end

  def index?
    user&.can_do_inventory?
  end

  def create?
    user&.can_do_inventory?
  end

  def new?
    user&.can_do_inventory?
  end

  def edit?
    user&.can_do_inventory?
  end

  def show?
    user&.can_do_inventory?
  end

  def update?
    user&.can_do_inventory?
  end

  def destroy?
    user&.is_admin?
  end

  def order?
    user&.can_do_inventory?
  end

  def order_all?
    user&.can_do_inventory?
  end

  def status?
    user&.admin_or_leader? || user&.can_do_inventory?
  end

  def paper?
    user&.admin_or_leader? || user&.can_do_inventory?
  end

  def labels?
    user&.admin_or_leader? || user&.can_do_inventory?
  end

  def financials?
    user&.can_do_inventory?
  end
end

