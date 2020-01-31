# frozen_string_literal: true

class Contactor
  include ActiveModel::Model

  attr_accessor :technology, :availability,
                :available_business_hours,
                :available_after_hours,
                :technology_ids,
                :emails

  def initialize(*args)
    super
    check_for_errors

    unless errors.any?
      determine_availability
      collect_technologies
      collect_emails
    end
  end

  def collect_emails
    User.leaders
        .where(available_business_hours: available_business_hours, available_after_hours: available_after_hours)
        .joins(:technologies)
        .where(technologies: { id: technology_ids} )
        .map(&:id)
  end

  private

  def check_for_errors
    errors.add[:availability, :invalid, message: "can't be blank"] unless self.availability.present?
    errors.add[:technology, :invalid, message: "can't be blank"] unless self.technology.present?
  end

  def collect_technologies
    if technology == '0'
      self.technology_ids = Technology.list_worthy.map(&:id)
    else
      self.technology_ids = [ technology.to_i ]
  end

  def determine_availability
    case availability
    when '0'
      self.available_business_hours = true
      self.available_after_hours = true
    when '1'
      self.available_business_hours = true
      self.available_after_hours = false
    when '2'
      self.available_business_hours = false
      self.available_after_hours = true
    else
      self.available_after_hours = false
      self.available_after_hours = true
    end
  end
end
