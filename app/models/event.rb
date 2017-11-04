class Event < ApplicationRecord
  has_one :location
  has_many :registrations
  has_many :users, through: :registrations
end
