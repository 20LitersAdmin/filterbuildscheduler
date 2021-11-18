# frozen_string_literal: true

class Assembly < ApplicationRecord
  # SCHEMA notes
  # 'combination' represents the 'parent' object
  # 'item' represents the 'child' object
  # #quantity stores the number of 'items' needed per 'combination'
  # 'price' is the cost of a single 'item' * #quantity
  # #depth is a rough calculation of the number of steps removed from the root Technology

  # simple_form field
  attr_accessor :item_search

  belongs_to :combination, polymorphic: true
  belongs_to :item, polymorphic: true

  validates_numericality_of :quantity, greater_than: 0

  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_price
  after_save :update_items_via_jobs
  after_destroy :update_items_via_jobs

  # ascending ensures that the "highest" nodes of the tree appear first
  scope :ascending, -> { order(:depth, :item_type, :item_id) }
  # descending ensures that the "lowest" nodes of the tree appear first
  scope :descending, -> { order(depth: :desc, item_type: :asc, item_id: :asc) }

  scope :ordered, -> { order(:item_type, :item_id) }

  scope :without_price_only, -> { where(affects_price_only: false) }

  scope :technology_combinations, -> { where(combination_type: 'Technology') }
  scope :component_combinations, -> { where(combination_type: 'Component') }
  scope :component_items, -> { where(item_type: 'Component') }
  scope :part_items, -> { where(item_type: 'Part') }

  def combination_uid
    "#{combination_type[0]}#{combination_id.to_s.rjust(3, 0.to_s)}"
  end

  def has_sub_items?
    return item.made_from_material? if item_type == 'Part'

    Assembly.where(combination: item).any?
  end

  def has_sub_components?
    return false if item_type == 'Part'

    Assembly.where(combination: item, item_type: 'Component').any?
  end

  def item_uid
    "#{item_type[0]}#{item_id.to_s.rjust(3, 0.to_s)}"
  end

  def name
    "#{combination_uid}>#{item_uid}"
  end

  def name_long
    "#{combination_uid} (#{combination.name}) > #{item_uid} (#{item.name})"
  end

  def quantity_hint
    "How many are needed to make one #{combination.name}?"
  end

  def sub_assemblies
    return Assembly.none if item_type == 'Part'

    Assembly.where(combination: item)
  end

  def sub_component_assemblies
    return Assembly.none if item_type == 'Part'

    Assembly.where(combination: item, item_type: 'Component')
  end

  def super_assemblies
    return Assembly.none if combination_type == 'Technology'

    Assembly.where(item: combination)
  end

  def types
    "#{combination_type}:#{item_type}"
  end

  private

  def calculate_price
    self.price_cents = item.price_cents * quantity
  end

  def update_items_via_jobs
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: %w[quantity_calc price_calc produceable], locked_at: nil).delete_all

    QuantityAndDepthCalculationJob.perform_later
    PriceCalculationJob.perform_later
    ProduceableJob.perform_later
  end
end
