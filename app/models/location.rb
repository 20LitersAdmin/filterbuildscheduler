class Location < ApplicationRecord

  validates :name, :address1, :city, :state, :zip, presence: true
end
