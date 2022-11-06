# frozen_string_literal: true

## =====> Hello, Interviewers!
# This Assembly model is my first swing at a tree-like structure
# in a Rails app. In brief:
# - a Technology is composed of many Components and Parts
# -- a Component is composed of many Components and/or Parts
# -- a Part may be composed of a Material
# (had this been a first-release feature, I might have used a single
# Item model instead of these three distinct models)
#
# Using a polymorphic join allows me a few main features.
# Because I can traverse up and down from any item, I can:
# * Use this join model to roll up the combination's price in an efficient way
# * Extrapolate how multiple item's inventory counts have changed
# based upon a change in the count of an up-stream (up-branch?) item
# * Predict how many items can be produced based upon the inventory of
# it's child items (traversing deeply downward)

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

  scope :with_price_only, -> { where(affects_price_only: true) }
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
    %w[quantity_calc price_calc produceable goal_remainder].each do |q|
      Sidekiq::Queue.new(q).clear
    end

    QuantityAndDepthCalculationJob.perform_later
    PriceCalculationJob.perform_later
    ProduceableJob.perform_later
    GoalRemainderCalculationJob.perform_later
  end
end
