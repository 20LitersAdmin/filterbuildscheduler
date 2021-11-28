# frozen_string_literal: true

class InventoryPolicy < ApplicationPolicy
  attr_reader :user, :inventory

  def initialize(user, inventory)
    @user = user
    @inventory = inventory

    super
  end

  def index?
    user&.can_do_inventory? || user&.can_view_inventory?
  end

  def new?
    user&.can_do_inventory?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def show?
    index?
  end

  def destroy?
    user&.is_admin?
  end

  def order?
    index?
  end

  def order_all?
    index?
  end

  def paper?
    index?
  end
end
