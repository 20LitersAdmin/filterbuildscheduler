# frozen_string_literal: true

## =====> Hello, Interviewers!
#
# Items (Technologies, Components, Parts, and Materials) are linked to
# each other via Assemblies, forming a tree structure
#
# They share so much business logic, that I wrote my first concern.
#
# I can see why some people love them and some people think they smell.

module Itemable
  extend ActiveSupport::Concern

  # CountTransferJob calls item.save, which could trigger #after_save :run_update_jobs and create and delete too many jobs
  # This attr is a flag we can check to prevent the after_save callback from triggering
  attr_accessor :saving_via_count_transfer_job

  # Items are: Technology, Component, Part, Material
  # Things Items have uniquely in common:
  # UIDs
  # Assemblies (except Technology can only be combination; Part can only be item)
  # loose_count, box_count, available_count, quantity_per_box
  # history
  # quantities (except Technology#quantities includes C, P, M, the others just include Tech)
  # price
  # label
  # can_be_produced (except Material)
  # goal_remainder (except Technology)

  included do
    monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

    scope :below_minimums, -> { kept.where(below_minimum: true) }
    scope :has_goal_remainder, -> { kept.where('goal_remainder > 0') }

    before_save :set_below_minimum

    before_save :update_available_count, if: -> { will_save_change_to_loose_count? || will_save_change_to_box_count? || will_save_change_to_quantity_per_box? }

    after_save :check_uid

    after_save :run_price_calculation_job, if: -> { saved_change_to_price_cents? }

    # The saving_via_count_transfer_job flag allows us to skip this callback when calling item.save within in the CountTransferJob
    after_update :run_update_jobs, if: -> { (saved_change_to_loose_count? || saved_change_to_box_count? || saved_change_to_quantity_per_box?) && !saving_via_count_transfer_job }
  end

  def all_technologies
    return [] if is_a?(Technology)

    # .technologies finds direct relations through Assembly, but doesn't include technologies where this part may be deeply nested in components through assemblies
    Technology.active.where('quantities ? :key', key: uid)
  end

  def all_technologies_names
    return short_name if is_a?(Technology)

    all_technologies.active&.pluck(:short_name)&.join(', ')
  end

  def all_technologies_ids
    return id if is_a?(Technology)

    all_technologies.active&.pluck(:id)&.join(',')
  end

  def allocate!
    return if [Technology, Material].include?(self.class) || super_assemblies.none?

    # don't bother with items that are only used in one assembly
    # allows for searching on non-blank assemblies
    if super_assemblies.count <= 1
      self.allocations = {}
      save
      return
    end

    super_assemblies.each do |assembly|
      combination = assembly.combination
      combination_uid = combination.uid

      allocations[combination_uid] = combination.goal_remainder * assembly.quantity
    end

    ttl = allocations.values.sum

    super_assemblies.each do |assembly|
      combination = assembly.combination
      combination_uid = combination.uid

      allocations[combination_uid] = (allocations[combination_uid] / ttl.to_f).round(2)
    end

    save
    reload
  end

  def box_language
    "#{quantity_per_box} / #{box_type}"
  end

  # get the closest date from the history JSON
  # if enforce_before: history date must be before or equal to date
  # if !enforced_before: use the closest date (before or after)
  # rubocop:disable Style/RedundantSort
  def count_as_of(date, enforce_before: false)
    date = Date.parse(date) if date.is_a?(String)

    return ArgumentError 'invalid date' unless date.is_a?(Date)

    return [available_count, date] if history.empty?

    return [available_count, history.keys.max] if date == Date.today

    closest_date =
      if enforce_before
        history.keys
               .sort
               .select { |k| Date.parse(k) < date }
               .last
      else
        # https://gist.github.com/robotmay/2479149
        history.keys
               .sort_by { |k| (Date.parse(k) - date).abs }
               .first
      end

    # Edge case: enforce_before == true and item has no history before date
    # meaning the item didn't exist in the system, so assume 0
    return [0, history.keys.max] if closest_date.nil?

    [history[closest_date]['available'], closest_date]
  end
  # rubocop:enable Style/RedundantSort

  def has_sub_assemblies?
    return false if is_a?(Material)

    return made_from_material? if is_a?(Part)

    # technology.assemblies
    # component.assemblies == component.sub_assemblies
    assemblies.any?
  end

  def history_only(key)
    return {} if history.empty?
    return unless %w[box loose inv_type available].include? key

    # History structure:
    # { date: { box: 99, loose: 99, inv_type: 'str', available: 99 }, ... }
    # history_only('box')
    # => [[date, 99][date, 99]...]
    history.map { |h| [h[0], h[1][key]] }
  end

  def history_series
    return [] if history.empty?

    if only_loose?
      [
        { name: 'Available', data: history_only('available') }
      ]
    else
      [
        { name: 'Available', data: history_only('available') },
        { name: 'Loose Count', data: history_only('loose') },
        { name: 'Box Count', data: history_only('box') }
      ]
    end
  end

  def history_hash_for_self(inventory_type)
    # this method is similar to Count#history_hash_for_item
    # However, counts for Shipping, Receiving and Event inventories only show the change, not the new _count values, which makes the item's history series incorrect
    # used by CountTransferJob#transfer_auto_count
    {
      inv_type: inventory_type,
      loose: loose_count,
      box: box_count,
      available: available_count
    }
  end

  def in_boxes_count
    return 0 if only_loose? || quantity_per_box.nil?

    box_count * quantity_per_box
  end

  def label_hash
    {
      name:,
      description:,
      uid:,
      technologies: all_technologies_names,
      quantity_per_box:,
      box_type:,
      box_notes:,
      picture:,
      only_loose: only_loose?
    }
  end

  def picture
    if image.attached?
      image
    else
      'http://placekitten.com/140/140'
    end
  end

  def quantity(item_uid)
    quantities[item_uid]
  end

  def quantities_with_tech_names_short
    return [] unless is_a? Technology

    ary = []

    quantities.each do |k, v|
      ary << [k.objectify_uid.short_name, v]
    end

    ary
  end

  # Rails Admin virtual
  def uid_and_name
    "#{uid}: #{name}"
  end

  def uid_and_short_name
    "#{uid}: #{short_name}"
  end

  private

  def check_uid
    update_columns(uid: "#{self.class.name[0]}#{id.to_s.rjust(3, '0')}") if uid.blank? || id != uid[1..].to_i || self.class.name[0] != uid[0]
  end

  def run_price_calculation_job
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Sidekiq::Queue.new('price_calc').clear
    PriceCalculationJob.perform_later
  end

  def run_update_jobs
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Sidekiq::Queue.new('produceable').clear
    ProduceableJob.perform_later

    Sidekiq::Queue.new('goal_remainder').clear
    GoalRemainderCalculationJob.perform_later
  end

  def set_below_minimum
    self.below_minimum = available_count.to_i < minimum_on_hand.to_i
  end

  def update_available_count
    self.available_count = loose_count.to_i

    self.available_count += (box_count.to_i * quantity_per_box.to_i) unless only_loose?
  end
end
