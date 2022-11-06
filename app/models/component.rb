# frozen_string_literal: true

class Component < ApplicationRecord
  include Discard::Model
  include Itemable
  # SCHEMA notes
  # #history is a JSON store of historical inventory counts: { date.iso8601 => { loose: 99, box: 99, available: 99 } }
  # #quantities is a JSON store of the total number (integer) needed per technology: { technology.uid => 99, technology.uid => 99 }

  # assembly_path wants to call @item.assemblies regardless of whether the @item is a Technology or Component
  alias_attribute :assemblies, :sub_assemblies

  # Technology.components && Component.components can react the same
  # alias_attribute :components, :sub_components

  has_many :super_assemblies, -> { where item_type: 'Component' }, class_name: 'Assembly', foreign_key: :item_id, dependent: :destroy
  has_many :sub_assemblies, -> { where combination_type: 'Component' }, class_name: 'Assembly', foreign_key: :combination_id, dependent: :destroy

  accepts_nested_attributes_for :sub_assemblies, allow_destroy: true

  has_many :technologies, through: :super_assemblies, source: :combination, source_type: 'Technology'
  has_many :parts, through: :sub_assemblies, source: :item, source_type: 'Part'

  has_one_attached :image, dependent: :purge
  attr_accessor :remove_image

  validates_presence_of :name

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  # https://stackoverflow.com/questions/69545741/ruby-on-rails-scope-of-polymorphic-join-with-only-specified-type
  # scope :with_only_parts, -> { joins(:parts).distinct }

  before_save :process_image, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }
  before_destroy :dependent_destroy_assemblies

  # Not in Itemable because it's unique to Component and Part
  def self.search_name_and_uid(string)
    return Component.none if string.blank? || !string.is_a?(String)

    ary = []
    args = string.tr(',', '').tr(';', '').split

    args.each do |arg|
      ary << "%#{arg}%"
    end

    Component.kept.where('name ILIKE any ( array[?] )', ary).or(where('uid ILIKE any ( array[?] )', ary))
  end

  # =====> Hello, Interviewers!
  #
  # I can write raw SQL when needed. Just sayin'.
  #
  # NOTE: will only find 1st-level parents, not all ancestors
  def super_components
    Component.kept.find_by_sql(
      "SELECT components.* FROM components
      INNER JOIN assemblies
      ON assemblies.combination_id = components.id
      AND assemblies.combination_type = 'Component'
      WHERE assemblies.item_type = 'Component'
      AND assemblies.item_id = #{id}"
    )
  end

  # NOTE: will only find 1st-level children, not all descendents
  def sub_components
    Component.kept.find_by_sql(
      "SELECT components.* FROM components
      INNER JOIN assemblies
      ON assemblies.item_id = components.id
      AND assemblies.item_type = 'Component'
      WHERE assemblies.combination_type = 'Component'
      AND assemblies.combination_id = #{id}"
    )
  end

  # Rails Admin virtual
  def uid_and_name
    "#{uid}: #{name}"
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
end
