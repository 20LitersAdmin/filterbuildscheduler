# frozen_string_literal: true

class TechnologyPolicy < ApplicationPolicy
  attr_reader :user, :technology

  def initialize(user, technology)
    @user = user
    @technology = technology

    super
  end

  def donation_list?
    user&.admin_or_leader?
  end

  def label?
    donation_list?
  end

  def labels?
    donation_list?
  end

  def labels_select?
    donation_list?
  end

  def status?
    user&.can_manage_data?
  end
end
