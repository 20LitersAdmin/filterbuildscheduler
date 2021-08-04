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

  # TODO: Second deploy
  scope :below_minimums, -> { where(below_minimum: true) }

  before_create :set_uid

  # TODO: Second deployment
  scope :kept, -> { all }
  scope :discarded, -> { none }
  scope :active, -> { kept }

  # TODO: Second deploy
  before_save :set_below_minimum

  # TODO: TEMP merge function
  def replace_with(material_id)
    materials_parts.update_all(material_id: material_id)

    self
  end

  def all_technologies
    # .technologies finds direct relations through Assembly, but doesn't include technologies where this material may be deeply nested in components or made from a nested part
    Technology.where('quantities ? :key', key: uid)
  end

  # TODO: Needs technologies.active
  def label_hash
    {
      name: name,
      description: description,
      uid: uid,
      technologies: technologies.pluck(:short_name),
      quantity_per_box: quantity_per_box,
      # TODO: image should not use picture
      image: picture,
      only_loose: only_loose?
    }
  end

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  def owners
    return ['N/A'] unless technologies.present?

    technologies.map(&:owner_acronym)
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

  def per_technologies
    technologies.map { |t| t.quantities[uid] }
  end

  def reorder?
    available_count < minimum_on_hand
  end

  def reorder_total_cost
    min_order * price
  end

  def technologies
    Technology.where('quantities ? :key', key: uid)
  end

  def tech_names_short
    all_technologies.pluck(:short_name)
  end

  # TODO: delete after 1st migration
  def uid
    "M#{id.to_s.rjust(3, 0.to_s)}"
  end

  def weeks_to_out
    return 0 if available_count.zero?

    monthly_rates = []
    all_technologies.each do |t|
      monthly_rates << t.monthly_production_rate * t.quantity(self)
    end

    return available_count if monthly_rates.sum.zero?

    (available_count / (monthly_rates.sum / 4.0)).round(-1)
  end

  private

  def set_below_minimum
    self.below_minimum = available_count < minimum_on_hand
  end

  def set_uid
    self.uid = "M#{id.to_s.rjust(3, 0.to_s)}"
  end
end
