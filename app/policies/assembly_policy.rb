# frozen_string_literal: true

class AssemblyPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def index?
    user&.admin_or_leader?
  end

  def items?
    index?
  end

  def price?
    index?
  end

  def show?
    index?
  end
end
