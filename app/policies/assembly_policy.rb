# frozen_string_literal: true

class AssemblyPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def index?
    user&.admin_or_leader?
  end

  def edit?
    index?
  end

  def new?
    index?
  end

  def price?
    index?
  end

  def show?
    index?
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
