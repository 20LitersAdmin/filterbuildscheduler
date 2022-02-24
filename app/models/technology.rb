# frozen_string_literal: true

class Technology < ApplicationRecord
  include Discard::Model
  include Itemable

  # SCHEMA notes
  # #history is a JSON store of historical inventory counts: { date.iso8601 => { loose: 99, box: 99, available: 99 } }
  # #quantities is a JSON store of the total number (integer / float) needed of each item [Component, Part, Material]: { item.uid => 99, item.uid => 99 }

  has_and_belongs_to_many :users
  has_many :events

  has_one_attached :image, dependent: :purge
  has_one_attached :display_image, dependent: :purge
  attr_accessor :remove_image, :remove_display_image

  has_many :assemblies, as: :combination, dependent: :destroy, inverse_of: :combination
  accepts_nested_attributes_for :assemblies, allow_destroy: true

  # TODO: doesn't actually work
  # has_many :components, through: :assemblies, source: :item, source_type: 'Component'
  has_many :parts, through: :assemblies, source: :item, source_type: 'Part'

  validates_presence_of :name, :short_name

  before_save :process_images, if: -> { attachment_changes.any? }
  after_save { image.purge if remove_image == '1' }
  after_save { display_image.purge if remove_display_image == '1' }
  after_save :run_goal_remainder_calculation_job, if: -> { saved_change_to_default_goal }

  before_destroy :manage_dependent_events

  # Exists in ActiveStorage already
  # scope :with_attached_image, -> { joins(:image_attachment) }
  scope :without_attached_image, -> { where.missing(:image_attachment) }

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :status_worthy, -> { kept.where('monthly_production_rate > ?', 0).order(monthly_production_rate: 'desc') }
  scope :list_worthy, -> { kept.where(list_worthy: true) }
  scope :finance_worthy, -> { kept.where.not(price_cents: 0).order(:name) }
  scope :with_set_goal, -> { kept.where.not(default_goal: 0) }

  def all_components
    # .components will find 1st-level children but not all descendents
    # so use the hash of all items stored in the quantities JSONB field
    uids = quantities.keys.grep(/^C[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('C', '').to_i }
    Component.kept.where(id: ary)
  end

  def all_parts
    # .parts will find 1st-level children but not all descendents
    # so use the hash of all items stored in the quantities JSONB field
    uids = quantities.keys.grep(/^P[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('P', '').to_i }
    Part.kept.where(id: ary)
  end

  def materials
    uids = quantities.keys.grep(/^M[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('M', '').to_i }
    # NOTE: `.kept` is intentionally not included
    Material.where(id: ary)
  end

  def owner_acronym
    owner.scan(/\b(\d+|\w)/).join
  end

  def parts_quantities
    uids = quantities.keys.grep(/^P[0-9]{3}/).sort
    ary = []
    uids.each do |uid|
      part = uid.objectify_uid
      ary << { uid: uid, name: part.name, quantity: quantities[uid], available: part.available_count }
    end

    ary.sort_by { |rec| rec[:name] }
  end

  def results_worthy?
    people.positive? &&
      lifespan_in_years.positive? &&
      liters_per_day.positive?
  end

  def short_name_w_owner
    "#{short_name} (#{owner_acronym})"
  end

  private

  def manage_dependent_events
    events.update_all(technology_id: nil)
  end

  def name_underscore
    # remove bad characters like commas etc
    # remove excess spaces
    # replace spaces with underscores
    # lowercase any capital letters
    name.gsub(/[^a-zA-Z0-9\s]/, '')
        .squish
        .tr(' ', '_')
        .downcase
  end

  def process_images
    attachment_changes.each do |ac|
      target = ac[0]
      file = attachment_changes[target].attachable

      # In RSpec, this is always a hash
      file = file[:io].path if file.instance_of?(Hash) && Rails.env.test?

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

  def run_goal_remainder_calculation_job
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'goal_remainder', locked_at: nil).delete_all

    GoalRemainderCalculationJob.perform_later
  end
end
