# frozen_string_literal: true

class Part < ApplicationRecord
  # TODO: Second deployment
  # include Discard::Model

  # TODO: Second deployment
  # has_one_attached :image, dependent: :purge

  has_many :materials_parts, dependent: :destroy
  has_many :materials, through: :materials_parts
  accepts_nested_attributes_for :materials_parts, allow_destroy: true

  has_many :assemblies, as: :item, dependent: :destroy
  has_many :components,   through: :assemblies, source: :combination, source_type: 'Component'
  has_many :technologies, through: :assemblies, source: :combination, source_type: 'Technology'
  accepts_nested_attributes_for :assemblies, allow_destroy: true

  belongs_to :supplier, optional: true

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  # scope :active, -> { kept }
  scope :available, -> { where('available_count > 0') }
  scope :orderable, -> { where(made_from_materials: false) }
  scope :made_from_materials, -> { where(made_from_materials: true) }
  scope :not_made_from_materials, -> { where(made_from_materials: false) }

  before_create :set_uid
  # TODO: Second deployment
  # before_save :set_made_from_materials

  # TODO: TEMP merge function
  def replace_with(part_id)
    assemblies.update_all(item_id: part_id)
    materials_parts.update_all(part_id: part_id) if made_from_materials?

    self
  end

  def all_technologies
    # .technologies finds direct relations through Assembly, but doesn't include technologies where this part may be deeply nested in components
    Technology.where('quantities ? :key', key: uid)
  end

  # TODO: fix this or un-use it
  def cprice
    return price unless (price.nil? || price.zero?) && made_from_materials?

    emp = extrapolate_material_parts.first

    return Money.new(0) if emp.nil?

    emp.material.price / emp.parts_per_material
  end

  # TODO: image should be probably needs to be adjusted
  # TODO: Needs technologies.active
  def label_hash
    {
      name: name,
      description: description,
      uid: uid,
      technologies: technologies.pluck(:short_name),
      quantity_per_box: quantity_per_box,
      image: picture,
      only_loose: only_loose?
    }
  end

  def material
    return Material.none unless made_from_materials?

    materials.first
  end

  def quantity_from_material
    return 0 unless materials.any?

    materials_parts.first.quantity.to_f
  end

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  def owners
    return ['N/A'] unless technologies.present?

    all_technologies.map(&:owner_acronym)
  end

  # TODO: replace this with image
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

  def superassemblies
    # alias of assemblies, for tree traversal up
    assemblies
  end

  def subassemblies
    Assembly.none
  end

  def technologies
    Technology.where('quantities ? :key', key: uid)
  end

  def tech_names_short
    all_technologies.pluck(:short_name)
  end

  # TODO: delete after 1st migration
  def uid
    "P#{id.to_s.rjust(3, 0.to_s)}"
  end

  # TODO: fix this or un-use it
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

  def set_made_from_materials
    self.made_from_materials = materials.any?
  end

  def set_uid
    self.uid = "P#{id.to_s.rjust(3, 0.to_s)}"
  end
end
