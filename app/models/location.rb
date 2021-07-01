# frozen_string_literal: true

class Location < ApplicationRecord
  # include Discard::Model
  # has_one_attached :image, dependent: :purge

  validates :name, :address1, :city, :state, :zip, presence: true

  # scope :active, -> { kept }

  def one_liner
    "#{city}, #{state} #{zip}"
  end

  def addr_one_liner
    "#{address1}, #{city}, #{state} #{zip}"
  end

  def address
    address2.present? ? "#{address1}, #{address2}" : address1
  end
end
