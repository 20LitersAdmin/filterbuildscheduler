class Location < ApplicationRecord
  acts_as_paranoid

  validates :name, :address1, :city, :state, :zip, presence: true
end
