class Event < ApplicationRecord
  belongs_to :location
  belongs_to :technology, optional: true
  has_many :registrations
  has_many :users, through: :registrations

  validates :start_time, :end_time, :title, presence: true
  validates :min_registrations, :max_registrations, :min_leaders, :max_leaders, numericality: { only_integer: true, greater_than: 0 }
  validate :dates_are_valid?
  validate :registrations_are_valid?

  scope :future, -> { where('end_time > ?', Time.now) }
  scope :past, -> { where('end_time <= ?', Time.now) }

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
  end

  def format_time_range
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime("%A, %D %l:%M%p") + end_time.strftime(" - %l:%M%p")
    else
      start_time.strftime("%A, %D at %l:%M%p") + end_time.strftime(" to %A, %D at %l:%M%p ")
    end
  end

  def total_registerted
    if registrations.present?
      registrations.map(&:guests_registered).reduce(:+) + users.size
    else
      0
    end
  end
end
