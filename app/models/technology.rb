# frozen_string_literal: true

class Technology < ApplicationRecord
  include Discard::Model
  include Itemable

  # SCHEMA notes
  # #history is a JSON store of historical inventory counts: { date.iso8601 => { loose: 99, box: 99, available: 99 } }
  # #quantities is a JSON store of the total number (integer / float) needed of each item [Component, Part, Material]: { item.uid => 99, item.uid => 99 }

  has_and_belongs_to_many :users

  has_one_attached :image, dependent: :purge
  has_one_attached :display_image, dependent: :purge
  attr_accessor :remove_image, :remove_display_image

  before_save :process_images, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }
  after_save { display_image.purge if remove_display_image == '1' }

  has_many :assemblies, as: :combination, dependent: :destroy, inverse_of: :combination
  accepts_nested_attributes_for :assemblies, allow_destroy: true

  has_many :components, through: :assemblies, source: :item, source_type: 'Component'
  has_many :parts, through: :assemblies, source: :item, source_type: 'Part'

  validates_presence_of :name, :short_name

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :status_worthy, -> { kept.where('monthly_production_rate > ?', 0).order(monthly_production_rate: 'desc') }
  scope :list_worthy, -> { kept.where(list_worthy: true) }
  scope :finance_worthy, -> { kept.where.not(price_cents: 0).order(:name) }

  def all_components
    # .components will find 1st-level children but not all descendents
    # so use the hash of all items stored in the quantities JSONB field
    uids = quantities.keys.grep(/^C[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('C', '').to_i }
    Component.active.where(id: ary)
  end

  def all_parts
    # .parts will find 1st-level children but not all descendents
    # so use the hash of all items stored in the quantities JSONB field
    uids = quantities.keys.grep(/^P[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('P', '').to_i }
    Part.active.where(id: ary)
  end

  def event_tech_goals_within(num = 0)
    events = Event.future.within_days(num).where(technology: self)

    events.map(&:item_goal).sum
  end

  def materials
    uids = quantities.keys.grep(/^M[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('M', '').to_i }
    # NOTE: `.active` is intentionally not included
    Material.where(id: ary)
  end

  def owner_acronym
    owner.gsub(/([a-z]|\s)/, '')
  end

  def short_name_w_owner
    "#{short_name} (#{owner_acronym})"
  end

  private

  def name_underscore
    name.tr(' ', '').underscore
  end

  def process_images
    # TODO: need to distringuish btw `image` and `display_image`.
    # hoping `attachment_changes['image'].attachable` and `attachment_changes['display_image'].attachable` will differentiate

    attachment_changes.each do |ac|
      target = ac[0]
      file = attachment_changes[target].attachable

      next if file.instance_of?(Hash)

      processed_image = ImageProcessing::MiniMagick
                        .source(File.open(file))
                        .resize_to_limit(600, 600)
                        .convert('png')
                        .call

      image_name = "#{name_underscore}_#{target}_#{Date.today.iso8601}.png"

      public_send(target).attach(io: File.open(processed_image.path), filename: image_name, content_type: 'image/png')
    end
  end
end
