# frozen_string_literal: true

class TechnologyPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def initialize(user, technology)
    @user = user
    @technology = technology

    super
  end

  def donation_list?
    item_lists?
  end

  def item_list?
    item_lists?
  end

  def item_lists?
    user&.admin_or_leader?
  end

  def label?
    item_lists?
  end

  def labels?
    item_lists?
  end

  def labels_select?
    item_lists?
  end

  def quantities?
    status?
  end

  def status?
    user&.can_manage_data?
  end

  def setup_list?
    item_lists?
  end
end
