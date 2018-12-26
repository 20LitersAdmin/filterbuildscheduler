# frozen_string_literal: true

class Location < ApplicationRecord
  acts_as_paranoid

  validates :name, :address1, :city, :state, :zip, presence: true

  scope :active, -> { where(deleted_at: nil) }

  def one_liner
    "#{city}, #{state} #{zip}"
  end

  def addr_one_liner
    "#{address1}, #{city}, #{state} #{zip}"
  end
end
