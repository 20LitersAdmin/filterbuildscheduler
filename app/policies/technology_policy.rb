# frozen_string_literal: true

class TechnologyPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def initialize(user, technology)
    @user = user
    @technology = technology
  end

  def index?
    user&.admin_or_leader?
  end

  def items?
    index?
  end

  def prices?
    index?
  end

  def label?
    index?
  end

  def assemble?
    index?
  end

  def labels?
    index?
  end

  def labels_select?
    index?
  end

  def donation_list?
    index?
  end
end
