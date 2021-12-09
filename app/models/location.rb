# frozen_string_literal: true

class Location < ApplicationRecord
  include Discard::Model

  has_many :events
  has_many :users, class_name: 'User', foreign_key: 'primary_location_id'
  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  validates_presence_of :name, :address1, :city, :state, :zip

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }

  before_destroy :manage_dependents

  def one_liner
    "#{city}, #{state} #{zip}"
  end

  def address
    address2.present? ? "#{address1}, #{address2}" : address1
  end

  def address_block
    area_is_present = city.present? || state.present? || zip.present?

    full_address = address.squish
    full_address += '<br />' if full_address.present? && area_is_present

    full_area = city.present? ? "#{city}, " : ''
    full_area += "#{state} #{zip}".squish if state.present? || zip.present?

    full_address += full_area unless full_area.blank?

    full_address&.html_safe
  end

  def addr_one_liner
    "#{address}, #{city}, #{state} #{zip}"
  end

  private

  def manage_dependents
    events.update_all(location_id: nil)

    users.update_all(primary_location_id: nil)
  end

  def name_underscore
    name.tr(' ', '').underscore
  end

  def process_image
    file = attachment_changes['image'].attachable

    # When this method is triggered properly, `file` is instance of `ActionDispatch::Http::UploadedFile`
    # but somehow `ImageProcessing::MiniMagick.call` causes this method to fire again
    # but this time `file` is the Hash from image.attach(io: String, filename: String, content_type: String), so...

    # In RSpec, this is always a hash
    file = file[:io].path if file.instance_of?(Hash) && Rails.env.test?

    return if file.instance_of?(Hash)

    processed_image = ImageProcessing::MiniMagick
                      .source(File.open(file))
                      .resize_to_limit(600, 600)
                      .convert('png')
                      .call

    image_name = "#{name_underscore}_#{Date.today.iso8601}.png"

    image.attach(io: File.open(processed_image.path), filename: image_name, content_type: 'image/png')
  end
end
