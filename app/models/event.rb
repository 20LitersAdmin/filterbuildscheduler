# frozen_string_literal: true

class Event < ApplicationRecord
  include Discard::Model

  belongs_to :location, optional: true
  belongs_to :technology, optional: true
  has_one :inventory
  has_many :registrations, dependent: :destroy
  accepts_nested_attributes_for :registrations

  has_many :users, through: :registrations
  has_one :inventory

  validates_presence_of :start_time, :end_time, :title

  validates :min_registrations, :max_registrations, :min_leaders, :max_leaders, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validates :technologies_built, :boxes_packed, :impact_results, :attendance, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :dates_are_valid?
  validate :registrations_are_valid?
  validate :leaders_are_valid?

  # RailsAdmin "active" is better than "kept"
  scope :active, -> { kept }

  scope :closed,          -> { kept.where('start_time <= ?', Time.now).order(start_time: :desc) }
  scope :complete,        -> { past.where('attendance != 0 OR technologies_built != 0 OR boxes_packed != 0') }
  scope :future,          -> { kept.where('end_time > ?', Time.now).order(start_time: :asc) }
  scope :needs_leaders,   -> {
    select('events.*')
      .left_joins(:registrations)
      .having('count(registrations.leader IS TRUE) < events.max_leaders')
      .group('events.id').future
  }

  scope :needs_report,    -> { kept.where('start_time <= ?', Time.now).where(attendance: 0).order(start_time: :desc) }
  scope :non_private,     -> { kept.where(is_private: false) }
  scope :past,            -> { kept.where('end_time <= ?', Time.now).order(start_time: :desc) }
  scope :pre_reminders,   -> { kept.where(reminder_sent_at: nil) }
  scope :with_attendance, -> { kept.where.not(attendance: 0) }
  scope :with_results,    -> { kept.where('technologies_built != 0 OR boxes_packed != 0') }
  scope :within_days,     ->(num) { kept.where('start_time <= ?', Time.now + num.days) }

  def builders_hours
    number_of_builders_attended * length
  end

  def builders_registered
    registrations.kept.builders
  end

  def builders_have_vs_total
    "#{total_registered} of #{max_registrations}"
  end

  def complete?
    return false if new_record?
    return false unless start_time < Time.zone.now

    attendance.positive? || technology_results.positive?
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
    return false if new_record?

    start_time > Time.zone.now
  end

  def in_the_past?
    return false if new_record?

    end_time <= Time.zone.now
  end

  def leaders_have_vs_needed
    "#{registrations.leaders.size} of #{max_leaders}"
  end

  def leaders_names
    return unless leaders_registered.present?

    registrations.kept.leaders
                 .map { |r| r.user.fname }
                 .join(', ')
  end

  def leaders_names_full
    return unless leaders_registered.present?

    registrations.kept.leaders
                 .map { |r| r.user.name }
                 .join(', ')
  end

  def leaders_registered
    registrations.kept.leaders
  end

  def leaders_hours
    number_of_leaders_attended * length
  end

  def length
    (end_time - start_time) / 1.hour
  end

  def mailer_time
    start_time.strftime('%a, %-m/%-d')
  end

  def needs_leaders?
    leaders_registered.count < max_leaders
  end

  def needs_report?
    attendance.zero?
  end

  def number_of_builders_attended
    attendance - number_of_leaders_attended
  end

  def number_of_leaders_attended
    registrations.kept.leaders.attended.size
  end

  def number_of_leaders_registered
    registrations.kept.leaders.size
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

  def really_needs_leaders?
    leaders_registered.count < min_leaders
  end

  def registrations_filled?
    total_registered >= max_registrations
  end

  def registrations_remaining
    return max_registrations if registrations.empty?

    max_registrations - total_registered
  end

  def registrations_remaining_without(registration)
    return max_registrations if registrations.kept.empty?

    max_registrations - total_registered_without(registration)
  end

  def registrations_would_overflow?(registration)
    (registration.guests_registered + 1) > registrations_remaining_without(registration)
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

  def results_liters_per_year
    results_liters_per_day * 365
  end

  def results_liters_lifespan
    results_liters_per_year * technology.lifespan_in_years
  end

  def should_allow_results_emails_to_be_sent?
    in_the_past? &&
      !emails_sent? &&
      registrations.kept.size.positive? &&
      (Date.today - end_time.to_date).round < 14
  end

  def should_create_inventory?
    return false if inventory.present?

    # edge case:
    # The event has been updated before, with report fields, but for some reason an inventory doesn't exist (maybe it was deleted?), and results fields were set to positive
    # now results fields are being changed, so check to make sure they aren't being zero-ed out

    (technologies_built_changed? || boxes_packed_changed?) &&
      (technologies_built.positive? || boxes_packed.positive?)
  end

  def should_notify_admins?
    start_time_was > Time.now &&
      important_fields_for_admins_changed?
  end

  def should_notify_builders?
    start_time_was > Time.now &&
      registrations.kept.any? &&
      important_fields_for_builders_changed?
  end

  def should_send_results_emails?
    # technology_results checks for complete?

    !emails_sent? &&
      technology_results.positive? &&
      attendance.positive? &&
      registrations.kept.any? &&
      technology.results_worthy?
  end

  def technology_results
    [(boxes_packed.to_i * technology.quantity_per_box.to_i) + technologies_built.to_i, impact_results.to_i].max
  end

  def total_registered
    return 0 if registrations.kept.empty?

    registrations.kept.sum(:guests_registered) + builders_registered.count
  end

  def total_registered_w_leaders
    return 0 if registrations.kept.empty?

    registrations.kept.sum(:guests_registered) + registrations.count
  end

  def total_registered_without(registration)
    return 0 if registrations.kept.empty?

    regs = registrations.kept.where.not(id: registration.id)

    regs.sum(:guests_registered) + regs.count
  end

  def volunteer_hours
    length * attendance
  end

  def you_are_attendee(user)
    ' (including you)' if user && registrations.where(user_id: user.id).where(leader: false).present?
  end

  def you_are_leader(user)
    ' (including you)' if user&.is_leader && registrations.where(user_id: user.id).where(leader: true).present?
  end

  private

  def dates_are_valid?
    return if start_time.nil? || end_time.nil?

    # accuracy to within a minute
    diff = ((end_time - start_time) / 1.minute).round
    errors.add(:end_time, 'must be after start time') unless diff.positive?
  end

  def important_fields_for_admins_changed?
    start_time_changed? ||
      end_time_changed? ||
      location_id_changed? ||
      technology_id_changed? ||
      is_private_changed?
  end

  def important_fields_for_builders_changed?
    start_time_changed? ||
      end_time_changed? ||
      location_id_changed?
  end

  def leaders_are_valid?
    return if min_leaders.nil? || max_leaders.nil?

    errors.add(:max_leaders, 'must be greater than min leaders') if min_leaders > max_leaders

    errors.add(:max_leaders, 'there are more registered leaders than the event max leaders') if leaders_registered.count > max_leaders
  end

  def registrations_are_valid?
    return if min_registrations.nil? || max_registrations.nil?

    errors.add(:max_registrations, 'must be greater than min registrations') if min_registrations > max_registrations

    errors.add(:max_registrations, 'there are more registered attendees than the event max registrations') if total_registered > max_registrations
  end
end
