# frozen_string_literal: true

class Supplier < ApplicationRecord
  acts_as_paranoid
  require 'uri'

  has_many :parts
  has_many :materials

  validates :name, presence: true
  validate :valid_url?
  validates :email, :poc_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true

  scope :active, -> { where(deleted_at: nil) }
  scope :without_parts, -> { left_outer_joins(:parts).where(parts: { id: nil }) }
  scope :without_materials, -> { left_outer_joins(:materials).where(materials: { id: nil }) }
  scope :without_items, -> { without_parts.without_materials }

  def valid_url?
    # Allow nil
    return true if url.nil?

    parsed_url = URI.parse(url)

    case
    when parsed_url.host.nil?
      errors.add(:url, 'Bad URL')
      false
    when parsed_url.host.length - parsed_url.host.gsub('.', '').length > 3
      errors.add(:url, 'Bad URL')
      false
    when parsed_url.scheme != 'http' && parsed_url.scheme != 'https'
      errors.add(:url, 'Must include http:// or https://')
      false
    else
      true
    end
  end

  def related_items(items)
    ary = []
    items.each do |c|
      ary << c if c.supplier == self
    end
    ary
  end
end
