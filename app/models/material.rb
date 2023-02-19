# frozen_string_literal: true

class Material < ApplicationRecord
  include Discard::Model
  include Itemable
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

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

  def allocate!
    return if parts.none?

    if parts.size == 1
      allocations[parts.first.uid] = 1.0
      save
      return
    end

    hsh = {}

    parts.each do |part|
      hsh[part.id] = (1 / part.quantity_from_material.to_f)
    end

    # hash contains:
    # { part_id: fraction_of_material_needed_for_1_part }

    ttl = hsh.values.sum

    parts.each do |part|
      # hsh[part.id] / ttl is
      # the fractional allocation of one material across all parts

      allocations[part.uid] = hsh[part.id] / ttl
      save
    end

    ttl
  end

  def assemblies
    # GoalRemainderCalculationJob wants materials to respond to #assemblies.size.positive?
    []
  end

  def can_be_produced
    0
  end

  # inverse of part.quantity_from_material
  def quantity_for_part(part)
    return 0 unless parts.any? && parts.pluck(:id).include?(part.id)

    return 0 if part.quantity_from_material.nil?

    part.quantity_from_material
  end

  def on_order?
    return false if last_ordered_at.blank? || last_ordered_quantity.nil?

    return true if last_received_at.nil?

    # partial order received, still waiting for the rest
    return true if partial_received?

    last_ordered_at > last_received_at
  end

  def order_language
    return '' unless on_order?

    if partial_received?
      "Awaiting #{human_number(partial_order_remainder)}<br/> from #{human_date(last_ordered_at)}".html_safe
    else
      "Ordered #{human_number(last_ordered_quantity)}<br/> on #{human_date(last_ordered_at)}".html_safe
    end
  end

  def partial_received?
    # has not been ordered, or has not been received
    return false unless last_ordered_at.present? && last_received_at.present? && last_received_quantity.to_i.positive?

    # last_received_at is before last_ordered_at
    return false if last_received_at < last_ordered_at

    # received in full within the last 3 months
    return false if last_received_quantity == last_ordered_quantity && (last_received_at - last_ordered_at).seconds.in_months <= 3

    # when receiving multiple partial orders, need to determine if full order has been recevived
    received_since_last_order < last_ordered_quantity.to_i
  end

  def partial_order_remainder
    return 0 unless on_order? && partial_received?

    last_ordered_quantity.to_i - received_since_last_order
  end

  def received_since_last_order
    # shipping, receiving and event inventories combine their counts with current item counts
    # so don't sum the values of the receiving inventory, look at the max value

    # Get history records where date key is greater than the last_ordered_at date && where inventory type is Receiving
    history.select { |k, v| Date.parse(k) > last_ordered_at && v['inv_type'] == 'Receiving' }
           .values.map { |r| r['available'] }
           .max.to_i
  end

  def owners
    return ['N/A'] unless all_technologies.present?

    all_technologies.kept.map(&:owner_acronym)
  end

  def reorder?
    available_count < minimum_on_hand
  end

  def reorder_total_cost
    min_order * price
  end

  def supplier_and_sku
    return supplier.name unless order_url.present?

    sku_sub = sku.presence || 'link'

    sku_as_link = ActionController::Base.helpers.link_to sku_sub, order_url, target: '_blank', rel: 'tooltip'

    "#{supplier.name} - SKU: #{sku_as_link}".html_safe
  end

  private

  def process_image
    file = attachment_changes['image'].attachable

    # When this method is triggered properly, `file` is instance of `ActionDispatch::Http::UploadedFile`
    # but apparently `ImageProcessing::MiniMagick.call` causes this callback to trigger again
    # but this time `file` is the Hash from image.attach(io: String, filename: String, content_type: String) so...

    # In RSpec, this is always a hash
    file = file[:io].path if file.instance_of?(Hash) && Rails.env.test?

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
