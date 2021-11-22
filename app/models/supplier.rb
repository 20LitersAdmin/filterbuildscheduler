# frozen_string_literal: true

class Supplier < ApplicationRecord
  include Discard::Model
  require 'uri'

  has_many :parts
  has_many :materials

  validates_presence_of :name
  validate :valid_url?
  validates :email, :poc_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :without_parts, -> { left_outer_joins(:parts).where(parts: { id: nil }) }
  scope :without_materials, -> { left_outer_joins(:materials).where(materials: { id: nil }) }
  scope :without_items, -> { without_parts.without_materials }

  def address_block
    area_is_present = city.present? || state.present? || province.present? || zip.present?

    full_address = address1.present? || address2.present? ? "#{address1} #{address2}".squish : ''
    full_address += '<br />' if full_address.present? && area_is_present

    full_area = city.present? ? "#{city}, " : ''
    full_area += "#{state} #{province}".squish if state.present? || province.present?
    full_area += " #{zip}" if zip.present?

    full_address += full_area unless full_area.blank?
    full_address += '<br />' if full_address.present? && country.present?
    full_address += country if country.present?

    full_address&.html_safe
  end

  def related_items(items)
    # ugly, but used for InventoriesController#order
    # items == [parts, materials].flatten
    items.map { |i| i if i.supplier_id == id }
  end

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
end
