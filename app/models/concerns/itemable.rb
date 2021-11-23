# frozen_string_literal: true

module Itemable
  extend ActiveSupport::Concern

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

  included do
    monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

    scope :below_minimums, -> { kept.where(below_minimum: true) }

    before_save :set_below_minimum

    before_save :update_available, if: -> { will_save_change_to_loose_count? || will_save_change_to_box_count? || will_save_change_to_quantity_per_box? }

    after_save :check_uid

    after_save :run_price_calculation_job, if: -> { saved_change_to_price_cents? }

    after_update :run_produceable_job, if: -> { saved_change_to_loose_count? || saved_change_to_box_count? || saved_change_to_quantity_per_box? }
  end

  def all_technologies
    return [] if is_a?(Technology)

    # .technologies finds direct relations through Assembly, but doesn't include technologies where this part may be deeply nested in components through assemblies
    Technology.kept.where('quantities ? :key', key: uid)
  end

  def all_technologies_names
    return short_name if is_a?(Technology)

    all_technologies.active&.pluck(:short_name)&.join(', ')
  end

  def all_technologies_ids
    return id if is_a?(Technology)

    all_technologies.active&.pluck(:id)&.join(',')
  end

  def has_sub_assemblies?
    return false if is_a?(Material)

    return made_from_material? if is_a?(Part)

    # technology.assemblies
    # component.assemblies == component.sub_assemblies
    assemblies.any?
  end

  def history_only(key)
    history.map { |h| [h[0], h[1][key]] }
  end

  def history_series
    [
      { name: 'Available', data: history_only('available') },
      { name: 'Loose Count', data: history_only('loose') },
      { name: 'Box Count', data: history_only('box') }
    ]
  end

  def label_hash
    {
      name: name,
      description: description,
      uid: uid,
      technologies: all_technologies_names,
      quantity_per_box: quantity_per_box,
      picture: picture,
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
    ary = []

    quantities.each do |k, v|
      ary << [k.objectify_uid.short_name, v]
    end

    ary
  end

  private

  def check_uid
    update_columns(uid: "#{self.class.to_s[0]}#{id.to_s.rjust(3, '0')}") if uid.blank? || id != uid[1..].to_i
  end

  def run_price_calculation_job
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'price_calc', locked_at: nil).delete_all

    PriceCalculationJob.perform_later
  end

  def run_produceable_job
    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'produceable', locked_at: nil).delete_all

    ProduceableJob.perform_later
  end

  def set_below_minimum
    self.below_minimum = available_count < minimum_on_hand
  end

  def update_available
    self.available_count = (box_count * quantity_per_box) + loose_count
  end
end
