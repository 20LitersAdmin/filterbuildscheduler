class Event < ApplicationRecord
  acts_as_paranoid

  belongs_to :location
  belongs_to :technology
  has_many :registrations
  has_many :users, through: :registrations

  validates :start_time, :end_time, :title, :min_leaders, :max_leaders, :min_registrations, :max_registrations, presence: true
  validates :min_registrations, :max_registrations, :min_leaders, :max_leaders, numericality: { only_integer: true, greater_than: 0 }
  validate :dates_are_valid?
  validate :registrations_are_valid?
  validate :leaders_are_valid?

  scope :non_private, -> { where(is_private: false) }
  scope :future, -> { where('end_time > ?', Time.now).order(start_time: :asc) }
  scope :past, -> { where('end_time <= ?', Time.now).order(start_time: :desc) }

  accepts_nested_attributes_for :registrations

  def in_the_past?
    return end_time <= Time.now
  end

  def dates_are_valid?
    return if start_time.nil? || end_time.nil?
    if start_time > end_time
      errors.add(:end_time, 'must be after start time')
    end
  end

  def registrations_are_valid?
    return if min_registrations.nil? || max_registrations.nil?
    if min_registrations > max_registrations
      errors.add(:max_registrations, 'must be greater than min registrations')
    end

    if total_registered > max_registrations
      errors.add(:max_registrations, 'there are more registered attendees than the event max registrations')
    end
  end

  def leaders_are_valid?
    return if min_leaders.nil? || max_leaders.nil?
    if min_leaders > max_leaders
      errors.add(:max_leaders, 'must be greater than min leaders')
    end

    if leaders_registered.count > max_leaders
      errors.add(:max_leaders, 'there are more registered leaders than the event max leaders')
    end
  end

  def format_time_range
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime("%a, %-m/%-d %l:%M%P") + end_time.strftime(" - %l:%M%P")
    else
      start_time.strftime("%a, %-m/%-d at %l:%M%P") + end_time.strftime(" to %a, %-m/%-d at %l:%M%P")
    end
  end

  def format_date_only
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime("%a, %-m/%-d")
    else
      start_time.strftime("%a, %-m/%-d %l:%M%P") + end_time.strftime(" to %a, %-m/%-d %l:%M%P")
    end
  end

  def format_time_only
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime("%l:%M%P") + end_time.strftime(" - %l:%M%P")
    else
      " "
    end
  end

  def total_registered
    if registrations.present?
      registrations.map(&:guests_registered).reduce(:+) + non_leaders_registered.count
    else
      0
    end
  end

  def non_leaders_registered
    registrations.non_leader
  end

  def leaders_registered
    registrations.registered_as_leader
  end

  def registrations_filled?
    total_registered >= max_registrations
  end

  def does_not_need_leaders?
    leaders_registered.count >= max_leaders
  end

  def really_needs_leaders?
    leaders_registered.count < min_leaders
  end

  def needs_leaders?
    leaders_registered.count < max_leaders
  end

  def incomplete?
    !complete?
  end

  def complete?
    technologies_built.present? && attendance.present?
  end

  def privacy_humanize
    if is_private == true
      "Private Event"
    else
      "Public Event"
    end
  end

  def mailer_time
    start_time.strftime('%a, %-m/%-d')
  end

  def leaders_names
    if leaders_registered.present?
      registrations.registered_as_leader.map { |r| r.user.fname }.join(', ')
    end
  end
end
