# frozen_string_literal: true

class InventoryPolicy
  attr_reader :user, :inventory

  def initialize(user, inventory)
    @user = user
    @inventory = inventory
  end

  def index?
    user&.does_inventory?
  end

  def create?
    user&.does_inventory?
  end

  def new?
    user&.does_inventory?
  end

  def edit?
    user&.does_inventory?
  end

  def show?
    user&.does_inventory?
  end

  def update?
    user&.does_inventory?
  end

  def destroy?
    user&.is_admin?
  end

  def order?
    user&.does_inventory?
  end

  def status?
    user&.admin_or_leader? || user&.does_inventory?
  end

  def paper?
    user&.admin_or_leader? || user&.does_inventory?
  end
end

