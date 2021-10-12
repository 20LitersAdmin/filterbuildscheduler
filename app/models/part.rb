# frozen_string_literal: true

class Part < ApplicationRecord
  include Discard::Model
  include Itemable

  # SCHEMA notes
  # #history is a JSON store of historical inventory counts: { date.iso8601 => { loose: 99, box: 99, available: 99 } }
  # #quantities is a JSON store of the total number (integer) needed per technology: { technology.uid => 99, technology.uid => 99 }

  alias_attribute :super_assemblies, :assemblies

  has_many :assemblies, as: :item, dependent: :destroy, inverse_of: :item
  has_many :components,   through: :assemblies, source: :combination, source_type: 'Component'
  has_many :technologies, through: :assemblies, source: :combination, source_type: 'Technology'
  accepts_nested_attributes_for :assemblies, allow_destroy: true

  belongs_to :material, optional: true
  belongs_to :supplier, optional: true

  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  validates_presence_of :name

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :available, -> { where('available_count > 0') }
  scope :orderable, -> { where(made_from_materials: false) }
  scope :made_from_material, -> { where(made_from_material: true) }
  scope :not_made_from_material, -> { where(made_from_material: false) }

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  before_save :set_made_from_material
  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }

  # Not in Itemable because it's unique to Component and Part
  def self.search_name_and_uid(string)
    return [] if string.blank? || !string.is_a?(String)

    ary = []
    args = string.tr(',', '').tr(';', '').split

    args.each do |arg|
      ary << "%#{arg}%"
    end

    Part.where('name ILIKE any ( array[?] )', ary).or(where('uid ILIKE any ( array[?] )', ary))
  end

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  # TODO: replace with Itemable#quantity(item)
  def per_technology(technology)
    technology.quantities[uid]
  end

  def per_technologies
    technologies.map { |t| t.quantities[uid] }
  end

  def reorder_total_cost
    min_order * price
  end

  def superassemblies
    # alias of assemblies, for tree traversal up
    assemblies
  end

  def supplier_and_sku
    return '' if made_from_materials?

    return supplier.name unless order_url.present?

    sku_as_link = ActionController::Base.helpers.link_to sku, order_url, target: '_blank', rel: 'tooltip'
    "#{supplier.name} - SKU: #{sku_as_link}".html_safe
  end

  def subassemblies
    Assembly.none
  end

  # Handled by has_many relationship
  # def technologies
  #   Technology.where('quantities ? :key', key: uid)
  # end

  def tech_names_short
    all_technologies.pluck(:short_name)
  end

  # Rails Admin virtual
  def uid_and_name
    "#{uid}: #{name}"
  end

  private

  def process_image
    file = attachment_changes['image'].attachable

    # When this method is triggered properly, `file` is instance of `ActionDispatch::Http::UploadedFile`
    # but apparently `ImageProcessing::MiniMagick.call` causes this callback to trigger again
    # but this time `file` is the Hash from image.attach(io: String, filename: String, content_type: String), so...
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

  def set_made_from_material
    self.made_from_material = material.present?
  end
end
