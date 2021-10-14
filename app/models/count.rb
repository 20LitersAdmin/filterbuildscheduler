# frozen_string_literal: true

class Count < ApplicationRecord
  attr_accessor :reorder

  belongs_to :inventory
  belongs_to :user, optional: true
  belongs_to :item, polymorphic: true

  validates_presence_of :inventory_id

  # TODO: un-use
  scope :not_components, -> { where(component_id: nil) }
  scope :changed, -> { where.not(user_id: nil) }
  scope :uncounted, -> { where(user_id: nil) }

  def available
    loose_count.to_i + box_count
  end

  def box_count
    item.quantity_per_box * unopened_boxes_count.to_i
  end

  def history_hash
    {
      loose: loose_count,
      box: unopened_boxes_count,
      available: available
    }
  end

  def group_by_tech
    item.technologies.map(&:id).min || 999
  end

  def link_text
    # return the correct link text for inventory/:id/edit
    return 'Edit' unless user_id.nil?

    return 'Loose Count' if partial_box

    return 'Box Count' if partial_loose

    Constants::Inventory::COUNT_BTN_TEXT[inventory.type_for_params.to_sym]
  end

  def link_class
    return 'blue' if user_id.present?

    return 'empty' if partial_box || partial_loose

    'yellow'
  end

  def sort_by_status
    return 2 if user_id.present?

    return 1 if partial_box || partial_loose

    0
  end
end
