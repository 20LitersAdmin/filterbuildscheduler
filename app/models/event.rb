class Event < ApplicationRecord
  belongs_to :location
  has_many :registrations
  has_many :users, through: :registrations
  validates :start_time, :end_time, :title, presence: true
  validates :min_registrations, :max_registrations, :min_leaders, :max_leaders, numericality: { only_integer: true, greater_than: 0 }
  scope :future, -> {where('start_time > ?', Time.now)}
  scope :past, -> {where('start_time <= ?', Time.now)}

end
