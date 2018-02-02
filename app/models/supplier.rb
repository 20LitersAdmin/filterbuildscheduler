class Supplier < ApplicationRecord
  acts_as_paranoid
  require 'uri'

  has_many :supplier_parts, dependent: :destroy, inverse_of: :supplier
  has_many :parts, through: :supplier_parts
  accepts_nested_attributes_for :supplier_parts, allow_destroy: true

  has_many :supplier_materials, dependent: :destroy, inverse_of: :supplier
  has_many :materials, through: :supplier_materials
  accepts_nested_attributes_for :supplier_materials, allow_destroy: true

  validates :name, presence: true
  validate :valid_url?
  validates :email, :POC_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true

  def valid_url?
    parsed_url = URI.parse(url)
    return true unless parsed_url.host.nil?
  rescue URI::InvalidURIError
    self.errors.add(:url, "Bad URL")
    false
  end
end