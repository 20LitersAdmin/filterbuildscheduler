# frozen_string_literal: true

class Component < ApplicationRecord
  # TODO: Second deployment
  include Discard::Model

  # assembly_path wants to call @item.assemblies regardless of whether the @item
  # is a Technology or Component
  alias_attribute :assemblies, :sub_assemblies

  has_many :super_assemblies, -> { where item_type: 'Component' }, class_name: 'Assembly', foreign_key: :item_id
  has_many :sub_assemblies, -> { where combination_type: 'Component' }, class_name: 'Assembly', foreign_key: :combination_id

  accepts_nested_attributes_for :sub_assemblies, allow_destroy: true

  has_many :technologies, through: :super_assemblies, source: :combination, source_type: 'Technology'
  has_many :parts, through: :sub_assemblies, source: :item, source_type: 'Part'

  # TODO: Second deployment
  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }

  # TODO: Second deployment (fails on migration)
  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  validates_presence_of :name

  # TODO: Second deployment remove
  # scope :kept, -> { all }
  # scope :discarded, -> { none }

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }
  after_save :check_uid
  before_destroy :dependent_destroy_assemblies

  def self.search_name_and_uid(string)
    return [] if string.blank? || !string.is_a?(String)

    ary = []
    args = string.tr(',', '').tr(';', '').split

    args.each do |arg|
      ary << "%#{arg}%"
    end

    Component.where('name ILIKE any ( array[?] )', ary).or(where('uid ILIKE any ( array[?] )', ary))
  end

  # TODO: TEMP merge function
  def replace_with(component_id)
    Assembly.where(combination: self).update_all(combination_id: component_id)

    Assembly.where(item: self).update_all(item_id: component_id)

    self
  end

  def all_technologies
    # .technologies finds direct relations through Assembly, but doesn't include technologies where this component may be deeply nested in other components
    Technology.where('quantities ? :key', key: uid)
  end

  # TODO: Needs .active
  # NOTE: will only find 1st-level parents, not all ancestors
  def super_components
    Component.find_by_sql(
      "SELECT * FROM components
      INNER JOIN assemblies
      ON assemblies.combination_id = components.id
      AND assemblies.combination_type = 'Component'
      WHERE assemblies.item_type = 'Component'
      AND assemblies.item_id = #{id}"
    )
  end

  # TODO: Needs .active
  # NOTE: will only find 1st-level children, not all descendents
  def sub_components
    Component.find_by_sql(
      "SELECT * FROM components
      INNER JOIN assemblies
      ON assemblies.item_id = components.id
      AND assemblies.item_type = 'Component'
      WHERE assemblies.combination_type = 'Component'
      AND assemblies.combination_id = #{id}"
    )
  end

  def label_hash
    {
      name: name,
      description: description,
      uid: uid,
      technologies: technologies.active.pluck(:short_name),
      quantity_per_box: quantity_per_box,
      image: image,
      only_loose: only_loose?
    }
  end

  # TODO: replace this with price_cents
  def cprice
    ary = []
    extrapolate_component_parts.each do |ecp|
      next if ecp&.part.nil?

      if ecp.part.made_from_materials? && ecp.part.price_cents.zero? && ecp.part.extrapolate_material_parts.any?
        emp = ecp.part.extrapolate_material_parts.first

        ary << emp.part_price * ecp.parts_per_component.to_i
      else
        ary << ecp.part_price * ecp.parts_per_component.to_i
      end
    end
    ary.sum
  end

  # TODO: un-use this
  def required?
    if extrapolate_technology_components.any?
      extrapolate_technology_components.first.required?
    else
      false
    end
  end

  # TODO: un-use this
  def technology
    technologies.first
  end

  # TODO: un-use this
  def total
    if latest_count
      latest_count.total
    else
      0
    end
  end

  # Rails Admin virtual
  def uid_and_name
    "#{uid}: #{name}"
  end

  def weeks_to_out
    # TODO: needs to traverse down through subassemblies
    nil
  end

  private

  def dependent_destroy_assemblies
    super_assemblies.destroy_all
    sub_assemblies.destroy_all
  end

  def process_image
    file = attachment_changes['image'].attachable

    # When this method is triggered properly, `file` is instance of `ActionDispatch::Http::UploadedFile`
    # but apparently `ImageProcessing::MiniMagick.call` causes this callback to trigger again
    # but this time `file` is the Hash from image.attach(io: String, filename: String, content_type: String) so...
    # Early return if file is a Hash
    return if file.instance_of?(Hash)

    processed_image = ImageProcessing::MiniMagick
                      .source(File.open(file))
                      .resize_to_limit(600, 600)
                      .convert('png')
                      .call

    image_name = "#{uid}_#{Date.today.iso8601}.png"

    image.attach(io: File.open(processed_image.path), filename: image_name, content_type: 'image/png')
  end

  def check_uid
    update_columns(uid: "C#{id.to_s.rjust(3, '0')}") if uid.blank? || id != uid[1..].to_i
  end
end
