# frozen_string_literal: true

class Component < ApplicationRecord
  # TODO: Second deployment
  # include Discard::Model

  # TODO: Second deployment
  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }

  # TODO: Second deployment
  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }

  # TODO: Second deployment
  scope :kept, -> { all }
  scope :discarded, -> { none }
  scope :active, -> { kept }

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  before_create :set_uid
  before_destroy :dependent_destroy_assemblies

  # TODO: TEMP merge function
  def replace_with(component_id)
    Assembly.where(combination: self).update_all(combination_id: component_id)

    Assembly.where(item: self).update_all(item_id: component_id)

    self
  end

  # associations through Assembly
  # TODO: Needs .active
  def technologies
    ids = Assembly.where(combination_type: 'Technology', item: self).pluck(:combination_id)
    Technology.where(id: ids)
  end

  def all_technologies
    # .technologies finds direct relations through Assembly, but doesn't include technologies where this component may be deeply nested in other components
    Technology.where('quantities ? :key', key: uid)
  end

  # TODO: Needs .active
  def superassemblies
    Assembly.where(item_id: id, item_type: 'Component')
  end

  # TODO: Needs .active
  def supercomponents
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
  def subassemblies
    Assembly.where(combination_id: id, combination_type: 'Component')
  end

  # TODO: Needs .active
  def subcomponents
    Component.find_by_sql(
      "SELECT * FROM components
      INNER JOIN assemblies
      ON assemblies.item_id = components.id
      AND assemblies.item_type = 'Component'
      WHERE assemblies.combination_type = 'Component'
      AND assemblies.combination_id = #{id}"
    )
  end
  # end associations

  # TODO: image should be probably needs to be adjusted
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

  def parts
    Part.joins(:assemblies).where('assemblies.combination_id = ? AND assemblies.combination_type = ?', id, 'Component')
  end

  # TODO: replace this with image
  def picture
    begin
      ActionController::Base.helpers.asset_path('uids/' + uid + '.jpg')
    rescue => error
      'http://placekitten.com/140/140'
    end
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

  # TODO: delete after 1st migration
  def uid
    "C#{id.to_s.rjust(3, '0')}"
  end

  def weeks_to_out
    # TODO: needs to traverse down through subassemblies
    nil
  end

  private

  def dependent_destroy_assemblies
    superassemblies.destroy_all
    subassemblies.destroy_all
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

  def set_uid
    self.uid = "C#{id.to_s.rjust(3, '0')}"
  end
end
