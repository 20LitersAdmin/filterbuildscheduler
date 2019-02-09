# frozen_string_literal: true

class Event < ApplicationRecord
  acts_as_paranoid

  belongs_to :location
  belongs_to :technology
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

  scope :active,       -> { where(deleted_at: nil) }
  scope :non_private,  -> { where(is_private: false) }
  scope :future,       -> { where('end_time > ?', Time.now).order(start_time: :asc) }
  scope :within_days,  ->(num) { where('start_time <= ?', Time.now + num.days) }
  scope :past,         -> { where('end_time <= ?', Time.now).order(start_time: :desc) }
  scope :needs_report, -> { where('start_time <= ?', Time.now).where(attendance: 0).order(start_time: :desc) }
  scope :closed, -> { where('start_time <= ?', Time.now).order(start_time: :desc) }

  # Not working as expected
  # scope :still_needs_leaders, -> { joins(:registrations).group('events.id').having('count(CASE WHEN registrations.leader THEN 1 END) < events.max_leaders') }

  def in_the_past?
    end_time <= Time.now
  end

  def has_begun?
    start_time < Time.now
  end

  def dates_are_valid?
    return if start_time.nil? || end_time.nil?

    # accuracy to within a minute
    diff = ((end_time - start_time) / 1.minute).round
    errors.add(:end_time, 'must be after start time') unless diff.positive?
  end

  def registrations_are_valid?
    return if min_registrations.nil? || max_registrations.nil?

    errors.add(:max_registrations, 'must be greater than min registrations') if min_registrations > max_registrations

    errors.add(:max_registrations, 'there are more registered attendees than the event max registrations') if total_registered > max_registrations
  end

  def leaders_are_valid?
    return if min_leaders.nil? || max_leaders.nil?

    errors.add(:max_leaders, 'must be greater than min leaders') if min_leaders > max_leaders

    errors.add(:max_leaders, 'there are more registered leaders than the event max leaders') if leaders_registered.count > max_leaders
  end

  def format_time_range
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime('%a, %-m/%-d %-l:%M%P') + ' - ' + end_time.strftime('%-l:%M%P')
    else
      start_time.strftime('%a, %-m/%-d %-l:%M%P') + ' to ' + end_time.strftime('%a, %-m/%-d at %-l:%M%P')
    end
  end

  def format_date_only
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime('%a, %-m/%-d')
    else
      start_time.strftime('%a, %-m/%-d %l:%M%P') + end_time.strftime(' to %a, %-m/%-d %l:%M%P')
    end
  end

  def format_time_only
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime('%l:%M%P') + end_time.strftime(' - %l:%M%P')
    else
      ' '
    end
  end

  def full_title
    start_time.strftime('%-m/%-d') + ' - ' + title
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

  def non_leaders_registered(scope = '')
    if scope == 'only_deleted'
      registrations.only_deleted.non_leader
    else
      registrations.non_leader
    end
  end

  def leaders_registered(scope = '')
    if scope == 'only_deleted'
      registrations.only_deleted.registered_as_leader
    else
      registrations.registered_as_leader
    end
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

  def does_not_need_leaders?(scope = '')
    if scope == 'only_deleted'
      leaders_registered('only_deleted').count >= max_leaders
    else
      leaders_registered.count >= max_leaders
    end
  end

  def really_needs_leaders?(scope = '')
    if scope == 'only_deleted'
      leaders_registered('only_deleted').count < min_leaders
    else
      leaders_registered.count < min_leaders
    end
  end

  def needs_leaders?(scope = '')
    if scope == 'only_deleted'
      leaders_registered('only_deleted').count < max_leaders
    else
      leaders_registered.count < max_leaders
    end
  end

  def incomplete?
    !complete?
  end

  def complete?
    attendance.present? && start_time < Time.now
  end

  def privacy_humanize
    if is_private == true
      'Private Event'
    else
      'Public Event'
    end
  end

  def mailer_time
    start_time.strftime('%a, %-m/%-d')
  end

  def leaders_names
    registrations.registered_as_leader.map { |r| r.user.fname }.join(', ') if leaders_registered.present?
  end

  def leaders_names_full
    registrations.registered_as_leader.map { |r| r.user.name }.join(', ') if leaders_registered.present?
  end

  def you_are_attendee(user, scope = '')
    if scope == 'only_deleted'
      ' (including you)' if user && registrations.only_deleted.where(user_id: user.id).where(leader: false).present?
    else
      ' (including you)' if user && registrations.where(user_id: user.id).where(leader: false).present?
    end
  end

  def you_are_leader(user, scope = '')
    if scope == 'only_deleted'
      ' (including you)' if user&.is_leader && registrations.only_deleted.where(user_id: user.id).where(leader: true).present?
    else
      ' (including you)' if user&.is_leader && registrations.where(user_id: user.id).where(leader: true).present?
    end
  end

  def technology_results
    return 0 if incomplete? || !technology.primary_component.present?

    (boxes_packed * technology.primary_component.quantity_per_box) + technologies_built
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

  def number_registered
    # this allows for a form field
  end

  def length
    (end_time - start_time) / 1.hour
  end

  def volunteer_hours
    length * attendance
  end
end
