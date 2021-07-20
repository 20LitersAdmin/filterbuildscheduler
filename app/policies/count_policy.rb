# frozen_string_literal: true

class CountPolicy
  attr_reader :user, :count

  def initialize(user, count)
    @user = user
    @count = count
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

  def labels?
    user&.can_do_inventory?
  end

  def label?
    user&.can_do_inventory?
  end

  def destroy?
    user&.is_admin?
  end
end

