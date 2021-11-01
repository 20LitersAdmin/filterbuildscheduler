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
  after_save :update_items_via_jobs
  after_destroy :update_items_via_jobs

  validates_numericality_of :quantity, greater_than: 0

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

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

  # TODO: trial code for Event#update performing logic
  def assembly_map(goal, map = [])
    # TODO: this is the starting idea for AssemblyService

    # I envision: Assembly.find(9).assembly_map(46)
    # [{ uid: "C031", provides: 45, remainder: 1}, uid: ["P072", "P069", "C030"], provides: 1, remainder: 0 ]

    needed_quantity = goal * quantity
    available_count = item.available_count
    provide         = [needed_quantity, available_count].min / quantity
    remainder       = goal - provide

    map << { uid: item.uid, can_make: provide, remainder: remainder }

    # passes to Itemable#assembly_map
    item.assembly_map(remainder, map) if remainder.positive? && item.has_sub_assemblies?
  end

  # TODO: trial code for Event#update performing logic
  def can_assemble?(integer)
    # TODO: this is a starting idea for how to traverse down a level, then across that level before going down to the next level, trying to find open doors and dead ends.

    # Assembly.find(9).can_assemble?(46) should eq yes
    # because assembly.item.available_count == 45 and
    # [["P072", 203], ["P069", 96], ["C030", 1]]

    # can't assemble negative numbers or zero
    return false unless integer.positive?

    needed_quantity = integer * quantity

    return true if item.available_count >= needed_quantity

    if item_type == 'Component'
      can_assemble_from_component?(needed_quantity)
    else # item_type == 'Part'
      can_assemble_from_part?(needed_quantity)
    end
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

  def update_items_via_jobs
    # TODO: Current: Run unless one exists
    # Better: If one exists, destroy it, then schedule a new one
    QuantityAndDepthCalculationJob.perform_later unless Delayed::Job.where(queue: 'quantity_calc').any?

    PriceCalculationJob.perform_later unless Delayed::Job.where(queue: 'price_calc').any?

    ProduceableJob.perform_later unless Delayed::Job.where(queue: 'produceable').any?
  end
end
