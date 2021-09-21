# frozen_string_literal: true

class InventoryPolicy < ApplicationPolicy
  attr_reader :user, :inventory

  def initialize(user, inventory)
    @user = user
    @inventory = inventory
  end

  def index?
    user&.can_do_inventory?
  end

  def create?
    index?
  end

  def new?
    index?
  end

  def edit?
    index?
  end

  def show?
    index?
  end

  def update?
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

  def status?
    index?
  end

  def paper?
    index?
  end

  def labels?
    index?
  end

  def financials?
    index?
  end
end

