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

  before_save :calculate_price
  after_save :recalculate_quantities_depths_prices
  after_destroy :recalculate_quantities_depths_prices

  validates_numericality_of :quantity, greater_than: 0

  # TODO: Second deployment
  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  # ascending ensures that the "highest" nodes of the tree appear first
  scope :ascending, -> { order(:depth, :item_type, :item_id) }
  # descending ensures that the "lowest" nodes of the tree appear first
  scope :descending, -> { order(depth: :desc, item_type: :asc, item_id: :asc) }

  scope :ordered, -> { order(:item_type, :item_id) }

  scope :technology_combinations, -> { where(combination_type: 'Technology') }
  scope :component_combinations, -> { where(combination_type: 'Component') }
  scope :component_items, -> { where(item_type: 'Component') }
  scope :part_items, -> { where(item_type: 'Part') }

  # TODO: temporary clean-up method
  # remove duplicates where items exist under this Component AND under a subcomponent of this component
  def remove_duplicates!
    return false unless has_sub_components?

    item_ids = []
    sub_component_assemblies.each do |sca|
      item_ids << sca.item.sub_assemblies.pluck(:item_id)
    end

    combination_delete = Assembly.where(combination: combination, item: item_ids.flatten)
    item_delete = Assembly.where(combination: item, item: item_ids.flatten)

    combination_delete.destroy_all
    item_delete.destroy_all
  end

  def combination_uid
    "#{combination_type[0]}#{combination_id.to_s.rjust(3, 0.to_s)}"
  end

  def has_sub_items?
    return item.made_from_materials? if item_type == 'Part'

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

    Assembly.where(item_id: combination_id, item_type: combination_type)
  end

  def types
    "#{combination_type}:#{item_type}"
  end

  private

  def calculate_price
    self.price_cents = item.price_cents * quantity
  end

  def recalculate_quantities_depths_prices
    # TODO: Current: Run unless on exists
    # Better: If one exists, destroy it, then schedule a new one
    QuantityAndDepthCalculationJob.perform_later unless Delayed::Job.where(queue: 'quantity_calc').any?
    PriceCalculationJob.perform_later unless Delayed::Job.where(queue: 'price_calc').any?
  end
end
