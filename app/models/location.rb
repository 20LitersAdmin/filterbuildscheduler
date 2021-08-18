# frozen_string_literal: true

class Location < ApplicationRecord
  # include Discard::Model
  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }

  validates :name, :address1, :city, :state, :zip, presence: true

  # TODO: Second deployment
  scope :kept, -> { all }
  scope :discarded, -> { none }
  scope :active, -> { kept }

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  def one_liner
    "#{city}, #{state} #{zip}"
  end

  def addr_one_liner
    "#{address1}, #{city}, #{state} #{zip}"
  end

  def address
    address2.present? ? "#{address1}, #{address2}" : address1
  end

  private

  def name_underscore
    name.tr(' ','').underscore
  end

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

    image_name = "#{name_underscore}_#{Date.today.iso8601}.png"

    image.attach(io: File.open(processed_image.path), filename: image_name, content_type: 'image/png')
  end
end
