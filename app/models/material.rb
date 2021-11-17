# frozen_string_literal: true

class Material < ApplicationRecord
  include Discard::Model
  include Itemable

  # SCHEMA notes
  # #history is a JSON store of historical inventory counts: { date.iso8601 => { loose: 99, box: 99, available: 99 } }
  # #quantities is a JSON store of the total number (float) needed per technology: { technology.uid => 99, technology.uid => 99 }

  has_many :parts
  belongs_to :supplier, optional: true

  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  validates_presence_of :name

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }
  scope :with_parts, -> { joins(:parts).distinct }

  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }
  after_save :escalate_price, if: -> { saved_change_to_price_cents? }

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  def owners
    return ['N/A'] unless technologies.present?

    technologies.kept.map(&:owner_acronym)
  end

  def reorder?
    available_count < minimum_on_hand
  end

  def reorder_total_cost
    min_order * price
  end

  def supplier_and_sku
    return supplier.name unless order_url.present?

    sku_as_link = ActionController::Base.helpers.link_to sku, order_url, target: '_blank', rel: 'tooltip'

    "#{supplier.name} - SKU: #{sku_as_link}".html_safe
  end

  def technologies
    Technology.where('quantities ? :key', key: uid)
  end

  def tech_names_short
    # Itemable#all_technologies
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

  def escalate_price
    return true unless parts.any?

    parts.each do |part|
      part_price = price_cents / part.quantity_from_material
      part.update_columns(price_cents: part_price)
    end
  end
end
