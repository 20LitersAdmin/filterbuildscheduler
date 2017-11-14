class Location < ApplicationRecord
  acts_as_paranoid

  validates :name, :address1, :city, :state, :zip, presence: true

  def one_liner
    "#{city}, #{state} #{zip}"
  end

  def addr_one_liner
    "#{address1}, #{city}, #{state} #{zip}"
  end
end
