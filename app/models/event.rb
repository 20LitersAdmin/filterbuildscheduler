# frozen_string_literal: true

class Event < ApplicationRecord
  # TODO: second deploy enable
  include Discard::Model

  belongs_to :location
  belongs_to :technology
  has_one :inventory
  has_many :registrations, dependent: :destroy
  accepts_nested_attributes_for :registrations

  has_many :users, through: :registrations
  has_one :inventory

  validates :start_time, :end_time, :title, :min_leaders, :max_leaders, :min_registrations, :max_registrations, :location_id, presence: true
  validates :min_registrations, :max_registrations, :min_leaders, :max_leaders, numericality: { only_integer: true, greater_than: 0 }
  validates :technologies_built, :boxes_packed, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :dates_are_valid?
  validate :registrations_are_valid?
  validate :leaders_are_valid?

  # RailsAdmin "active" is better than "kept"
  scope :active, -> { kept }

  scope :non_private,   -> { where(is_private: false) }
  scope :pre_reminders, -> { where(reminder_sent_at: nil) }
  scope :future,        -> { where('end_time > ?', Time.now).order(start_time: :asc) }
  scope :within_days,   ->(num) { where('start_time <= ?', Time.now + num.days) }
  scope :past,          -> { where('end_time <= ?', Time.now).order(start_time: :desc) }
  scope :needs_report,  -> { where('start_time <= ?', Time.now).where(attendance: 0).order(start_time: :desc) }
  scope :closed,        -> { where('start_time <= ?', Time.now).order(start_time: :desc) }
  scope :needs_leaders, -> { future.select('events.*').joins('LEFT OUTER JOIN registrations ON (registrations.event_id = events.id)').having('count(registrations.leader IS TRUE) < events.max_leaders').group('events.id') }

  def builders_attended
    attendance - leaders_attended
  end

  def builders_hours
    builders_attended * length
  end

  def complete?
    attendance.present? && start_time < Time.zone.now
  end

  def dates_are_valid?
    return if start_time.nil? || end_time.nil?

    # accuracy to within a minute
    diff = ((end_time - start_time) / 1.minute).round
    errors.add(:end_time, 'must be after start time') unless diff.positive?
  end

  def does_not_need_leaders?(scope = '')
    if scope == 'only_deleted'
      leaders_registered('only_deleted').count >= max_leaders
    else
      leaders_registered.count >= max_leaders
    end
  end

  def format_date_only
    if start_time.to_date == end_time.to_date
      start_time.strftime('%a, %-m/%-d')
    else
      start_time.strftime('%a, %-m/%-d %l:%M%P') + end_time.strftime(' to %a, %-m/%-d %l:%M%P')
    end
  end

  def format_date_w_year
    if start_time.to_date == end_time.to_date
      start_time.strftime('%a, %-m/%-d/%y')
    else
      start_time.strftime('%a, %-m/%-d/%y') + end_time.strftime(' to %a, %-m/%-d')
    end
  end

  def format_time_range
    if start_time.to_date == end_time.to_date
      "#{start_time.strftime('%a, %-m/%-d %-l:%M%P')} - #{end_time.strftime('%-l:%M%P')}"
    else
      "#{start_time.strftime('%a, %-m/%-d %-l:%M%P')} to #{end_time.strftime('%a, %-m/%-d at %-l:%M%P')}"
    end
  end

  def format_time_only
    if start_time.to_date == end_time.to_date
      start_time.strftime('%l:%M%P') + end_time.strftime(' - %l:%M%P')
    else
      ' '
    end
  end

  def format_time_slim
    start_time.strftime('%-l:%M%P').sub(':00', '') + end_time.strftime('-%-l:%-M%P').sub(':00', '')
  end

  def full_title
    "#{start_time.strftime('%-m/%-d')} - #{title}"
  end

  def full_title_w_year
    "#{start_time.strftime('%-m/%-d/%y')} - #{title}"
  end

  def has_begun?
    start_time < Time.zone.now
  end

  def has_inventory?
    inventory.present?
  end

  def incomplete?
    !complete?
  end

  def in_the_future?
    end_time >= Time.zone.now
  end

  def in_the_past?
    end_time <= Time.zone.now
  end

  def leaders_are_valid?
    return if min_leaders.nil? || max_leaders.nil?

    errors.add(:max_leaders, 'must be greater than min leaders') if min_leaders > max_leaders

    errors.add(:max_leaders, 'there are more registered leaders than the event max leaders') if leaders_registered.count > max_leaders
  end

  def leaders_attended
    registrations.leaders.attended.size
  end

  def leaders_have_vs_needed
    "#{registrations.leaders.size} of #{max_leaders}"
  end

  def leaders_names
    return unless leaders_registered.present?

    registrations.leaders
                 .map { |r| r.user.fname }
                 .join(', ')
  end

  def leaders_names_full
    return unless leaders_registered.present?

    registrations.leaders
                 .map { |r| r.user.name }
                 .join(', ')
  end

  # TODO: remove only_deleted
  def leaders_registered(scope = '')
    if scope == 'only_deleted'
      registrations.only_deleted.leaders
    else
      registrations.leaders
    end
  end

  def leaders_hours
    leaders_attended * length
  end

  def length
    (end_time - start_time) / 1.hour
  end

  def mailer_time
    start_time.strftime('%a, %-m/%-d')
  end

  # TODO: remove only_deleted
  def needs_leaders?(scope = '')
    if scope == 'only_deleted'
      leaders_registered('only_deleted').count < max_leaders
    else
      leaders_registered.count < max_leaders
    end
  end

  def needs_report?
    attendance.zero?
  end

  # TODO: remove only_deleted
  def non_leaders_registered(scope = '')
    if scope == 'only_deleted'
      registrations.only_deleted.non_leader
    else
      registrations.non_leader
    end
  end

  def number_registered
    # this allows for a form field
  end

  def privacy_humanize
    if is_private == true
      'Private Event'
    else
      'Public Event'
    end
  end

  def really_needs_leaders?(scope = '')
    if scope == 'only_deleted'
      leaders_registered('only_deleted').count < min_leaders
    else
      leaders_registered.count < min_leaders
    end
  end

  def registrations_are_valid?
    return if min_registrations.nil? || max_registrations.nil?

    errors.add(:max_registrations, 'must be greater than min registrations') if min_registrations > max_registrations

    errors.add(:max_registrations, 'there are more registered attendees than the event max registrations') if total_registered > max_registrations
  end

  def registrations_filled?(scope = '')
    if scope == 'only_deleted'
      total_registered('only_deleted') >= max_registrations
    else
      total_registered >= max_registrations
    end
  end

  def registrations_remaining(scope = '')
    if scope == 'only_deleted'
      max_registrations - total_registered('only_deleted')
    else
      max_registrations - total_registered
    end
  end

  def results_people
    return 0 if technology.people.zero? || technology_results.zero?

    technology_results * technology.people
  end

  def results_timespan
    return 0 if technology.lifespan_in_years.zero? || technology_results.zero?

    technology.lifespan_in_years
  end

  def results_liters_per_day
    return 0 if technology.liters_per_day.zero? || technology_results.zero?

    technology_results * technology.liters_per_day
  end

  def technology
    return unless technology_id.present?

    Technology.find(technology_id)
  end

  def technology_results
    return 0 if incomplete? || !technology.primary_component.present?

    (boxes_packed * technology.primary_component.quantity_per_box) + technologies_built
  end

  # pass total_registered('only_deleted') to get access to registrations.only_deleted
  def total_registered(scope = '')
    if scope == 'only_deleted'
      registrations.only_deleted.exists? ? registrations.only_deleted.map(&:guests_registered).sum + non_leaders_registered('only_deleted').count : 0
    else
      registrations.exists? ? registrations.map(&:guests_registered).sum + non_leaders_registered.count : 0
    end
  end

  def total_registered_w_leaders(scope = '')
    if scope == 'only_deleted'
      registrations.only_deleted.exists? ? registrations.only_deleted.map(&:guests_registered).sum + registrations.only_deleted.count : 0
    else
      registrations.exists? ? registrations.map(&:guests_registered).sum + registrations.count : 0
    end
  end

  def volunteer_hours
    length * attendance
  end

  # TODO: only_deleted switch
  def you_are_attendee(user, scope = '')
    if scope == 'only_deleted'
      ' (including you)' if user && registrations.only_deleted.where(user_id: user.id).where(leader: false).present?
    else
      ' (including you)' if user && registrations.where(user_id: user.id).where(leader: false).present?
    end
  end

  # TODO: only_deleted switch
  def you_are_leader(user, scope = '')
    if scope == 'only_deleted'
      ' (including you)' if user&.is_leader && registrations.only_deleted.where(user_id: user.id).where(leader: true).present?
    else
      ' (including you)' if user&.is_leader && registrations.where(user_id: user.id).where(leader: true).present?
    end
  end

  private

  def convert_hour(hour)
    _quotient, modulus = hour.divmod(12)
    (modulus.zero? ? 12 : modulus).to_s
  end
end
