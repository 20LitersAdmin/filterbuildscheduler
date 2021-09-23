# frozen_string_literal: true

class CombinationPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def show?
    user&.admin_or_leader?
  end

  def edit?
    show?
  end

  def price?
    show?
  end

  def open_modal_form?
    edit?
  end

  def update?
    edit?
  end

  def create?
    new?
  end
end
