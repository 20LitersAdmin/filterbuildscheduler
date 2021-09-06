# frozen_string_literal: true

class Count < ApplicationRecord
  attr_accessor :reorder

  belongs_to :inventory
  belongs_to :user, optional: true
  belongs_to :item, polymorphic: true

  validates :inventory_id, :loose_count, :unopened_boxes_count, presence: true
  validates :loose_count, :unopened_boxes_count, numericality: { only_integer: true }

  scope :not_components, -> { where(component_id: nil) }
  scope :changed, -> { where.not(user_id: nil) }

  scope :updated_since, ->(time) { where('updated_at > ?', time) }

  def available
    loose_count + box_count
  end

  def avail_value
    available * item.price
  end

  def box_count
    item.quantity_per_box * unopened_boxes_count
  end

  # TODO: fix or remove
  # def can_produce_x_parent
  #   return 0 if available.zero?

  #   case type
  #   when 'material'
  #     # Materials are larger than parts (1 material makes many parts)
  #     material.extrapolate_material_parts.any? ? available * material.extrapolate_material_parts.first.parts_per_material.to_i : available
  #   when 'part'
  #     part.extrapolate_component_parts.any? ? available / part.extrapolate_component_parts.first.parts_per_component.to_i : available
  #   when 'component'
  #     available / item.per_technology
  #   end
  # end

  # TODO: fix or remove
  # def can_produce_x_tech
  #   available.zero? ? 0 : available / item.per_technology
  # end

  def diff_from_previous(field)
    case field
    when 'loose'
      loose_count - previous_loose
    when 'box'
      unopened_boxes_count - previous_box
    else
      0
    end
  end

  def group_by_tech
    item.technologies.map(&:id).min || 999
  end

  # history_json is used by a job to update item's history when inventory is marked complete,
  # before record is destroyed
  def history_json
    {
      loose: loose_count,
      box: unopened_boxes_count,
      available: available
    }
  end

  # TODO: remove after first migration
  def item
    return super if Count.column_names.include?('item_type')

    if part_id.present?
      Part.find(part_id)
    elsif material_id.present?
      Material.find(material_id)
    else
      Component.find(component_id)
    end
  end

  def last_ordered_at
    item.last_ordered_at
  end

  def last_ordered_quantity
    item.last_ordered_quantity
  end

  def link_text
    # return the correct link text for inventory/:id/edit
    return 'Edit' unless user_id.nil?

    return 'Loose Count' if partial_box

    return 'Box Count' if partial_loose

    Constants::Inventory::COUNT_BTN_TEXT[inventory.type_for_params.to_sym]
  end

  def link_class
    return 'blue' unless user_id.nil?

    return 'empty' if partial_box || partial_loose

    'yellow'
  end

  def minimum_on_hand
    item.minimum_on_hand
  end

  def min_order
    item.min_order
  end

  def name
    item.name
  end

  def owner
    return 'N/A' unless item.technologies.present?

    item.technologies.map(&:owner_acronym).uniq.join(',')
  end

  def per_technology
    item.per_technology
  end

  def previous_box
    previous_count['box']
  end

  def previous_count
    date = inventory.date.iso8601
    prev_date = item.history.keys.sort.reverse.find { |d| d <= date }

    return { 'box': 0, 'loose': 0 } if prev_date.nil?

    item.history[prev_date]
  end

  # TODO: this should be unnecessary
  def previous_inventory
    Inventory.latest_since(inventory.created_at)
  end

  def previous_loose
    previous_count['loose']
  end

  def price
    item.price
  end

  def reorder?
    type != 'component' && available < item.minimum_on_hand
  end

  def reorder_total_cost
    item.reorder_total_cost
  end

  def sort_by_user
    if user_id.present?
      1
    else
      0
    end
  end

  def supplier
    item.supplier
  end

  def tech_ids
    return item.id if item_type == 'Technology'

    ids = item.technologies.pluck(:id)

    if ids.empty?
      'n/a'
    else
      ids.join(',')
    end
  end

  def tech_names
    return item.name if item_type == 'Technology'

    if item.technologies.map(&:name).empty?
      'not associated'
    else
      item.technologies.map(&:name).join(', ')
    end
  end

  def tech_names_short
    return item.short_name if item_type == 'Technology'

    if item.technologies.map(&:name).empty?
      'n/a'
    else
      item.technologies.pluck(:short_name).join(', ')
      # item.technologies.map { |t| t.name.gsub(' Filter', '').gsub(' for Bucket', '') }.join(', ')
    end
  end

  def technology
    item.technology
  end

  def technologies
    item.technologies
  end

  # def total
  #   inventory.completed_at.nil? ? 'Not Finalized' : available + extrapolated_count
  # end

  def ttl_value
    return '-' if inventory.completed_at.blank?

    total * item.price
  end

  def type
    if part_id.present?
      'part'
    elsif material_id.present?
      'material'
    else
      'component'
    end
  end

  def weeks_to_deliver
    item.weeks_to_deliver
  end

  def weeks_to_out
    return 0 if available.zero?

    mpr = item.technology.present? ? item.technology.monthly_production_rate : 0
    can_produce_x_tech / (mpr / 4.0)
  end
end
