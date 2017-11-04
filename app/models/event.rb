class Event < ApplicationRecord
  belongs_to :location
  has_many :registrations
  has_many :users, through: :registrations
end
