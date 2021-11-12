# frozen_string_literal: true

class Contactor
  include ActiveModel::Model

  attr_accessor :technology, :availability,
                :available_business_hours,
                :available_after_hours,
                :technology_ids,
                :user_ids

  def initialize(*args)
    super
    self.user_ids = []

    return unless technology.present? && availability.present?

    self.technology_ids = []

    determine_availability
    collect_technologies
    collect_ids
  end

  def collect_ids
    self.user_ids = User.kept
                        .leaders
                        .where(available_business_hours: available_business_hours, available_after_hours: available_after_hours)
                        .joins(:technologies)
                        .where(technologies: { id: technology_ids })
                        .map(&:id)
                        .uniq
  end

  def empty?
    user_ids.empty? && technology.nil? && availability.nil?
  end

  private

  def collect_technologies
    self.technology_ids = technology == '0' ? Technology.list_worthy.map(&:id) : [technology.to_i]
  end

  def determine_availability
    # availability = [['All hours', 0], ['Business hours', 1], ['After-hours', 2]]
    case availability
    when '0'
      self.available_business_hours = [true, false]
      self.available_after_hours = [true, false]
    when '1'
      self.available_business_hours = true
      self.available_after_hours = [true, false]
    else # when '2'
      self.available_business_hours = [true, false]
      self.available_after_hours = true
    end
  end
end
