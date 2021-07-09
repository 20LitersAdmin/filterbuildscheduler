# frozen_string_literal: true

class Material < ApplicationRecord
  # TODO: Second deployment
  # include Discard::Model

  has_many :materials_parts, dependent: :destroy
  has_many :parts, through: :materials_parts
  accepts_nested_attributes_for :materials_parts, allow_destroy: true

  # TODO: Second deployment
  # has_one_attached :image, dependent: :purge

  belongs_to :supplier, optional: true

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  # TODO: Second deployment
  # scope :active, -> { kept }

  # TODO: TEMP merge function
  def replace_with(material_id)
    materials_parts.update_all(material_id: material_id)

    self
  end

  def available
    if latest_count.present?
      latest_count.available
    else
      0
    end
  end

  def latest_count
    Count.where(inventory: Inventory.latest_completed, material: self).first
  end

  # TODO: remove this
  def made_from_materials?
    false
  end

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  def owner
    return 'N/A' unless technologies.present?

    technologies.map(&:owner_acronym).uniq.join(',')
  end

  def picture
    begin
      ActionController::Base.helpers.asset_path("uids/#{uid}.jpg")
    rescue => e
      'http://placekitten.com/140/140'
    end
  end

  def per_technology(technology)
    technology.quantities[uid]
  end

  def reorder?
    available < minimum_on_hand
  end

  def reorder_total_cost
    min_order * price
  end

  def required?
    if extrapolate_technology_materials.any?
      extrapolate_technology_materials.first.required?
    else
      false
    end
  end

  def technologies
    Technology.where('quantities ? :key', key: uid)
  end

  def tech_names_short
    if technologies.map(&:name).empty?
      'n/a'
    else
      technologies.map { |t| t.name.gsub(' Filter', '').gsub(' for Bucket', '') }.join(', ')
    end
  end

  def uid
    "M#{id.to_s.rjust(3, 0.to_s)}"
  end

  def weeks_to_out
    latest_count.present? ? latest_count.weeks_to_out : 0
  end
end
