# frozen_string_literal: true

class Part < ApplicationRecord
  include Discard::Model
  include Itemable
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

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
  # When #made_from_material? #quantity_from_material must be set
  validates_presence_of :quantity_from_material, if: :made_from_material

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :available, -> { kept.where('available_count > 0') }
  scope :made_from_material, -> { kept.where(made_from_material: true) }
  scope :not_made_from_material, -> { kept.where(made_from_material: false) }

  class << self
    alias orderable not_made_from_material
  end

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  before_validation :set_made_from_material
  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }
  after_save :run_jobs_related_to_quantity_from_material, if: -> { saved_change_to_quantity_from_material? || saved_change_to_made_from_material? }

  # Not in Itemable because it's unique to Component and Part
  def self.search_name_and_uid(string)
    return Part.none if string.blank? || !string.is_a?(String)

    ary = []
    args = string.tr(',', '').tr(';', '').split

    args.each do |arg|
      ary << "%#{arg}%"
    end

    Part.kept.where('name ILIKE any ( array[?] )', ary).or(where('uid ILIKE any ( array[?] )', ary))
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
    history.select { |key, value| Date.parse(key) > last_ordered_at && value['inv_type'] == 'Receiving' }
           .values.map { |r| r['available'] }
           .max.to_i
  end

  def reorder?
    available_count < minimum_on_hand
  end

  def reorder_total_cost
    min_order * price
  end

  def super_assemblies
    # alias of assemblies, for tree traversal up
    assemblies
  end

  def supplier_and_sku
    return '' if made_from_material?

    return supplier.name unless order_url.present?

    sku_sub = sku.presence || 'link'

    sku_as_link = ActionController::Base.helpers.link_to sku_sub, order_url, target: '_blank', rel: 'tooltip'

    "#{supplier.name} - SKU: #{sku_as_link}".html_safe
  end

  def sub_assemblies
    Assembly.none
  end

  private

  def process_image
    file = attachment_changes['image'].attachable

    # When this method is triggered properly, `file` is instance of `ActionDispatch::Http::UploadedFile`
    # but apparently `ImageProcessing::MiniMagick.call` causes this callback to trigger again
    # but this time `file` is the Hash from image.attach(io: String, filename: String, content_type: String), so...

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

  def run_jobs_related_to_quantity_from_material
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Sidekiq::Queue.new('produceable').clear
    ProduceableJob.perform_later

    Sidekiq::Queue.new('goal_remainder').clear
    GoalRemainderCalculationJob.perform_later

    # reset the fractional allocation of a material to all the parts made from that material
    reload.material&.allocate!
  end

  def set_made_from_material
    self.made_from_material = material.present?

    self.quantity_from_material = 1.0 if quantity_from_material&.zero?
  end
end
