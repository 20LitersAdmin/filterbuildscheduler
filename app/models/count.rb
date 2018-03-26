class Count < ApplicationRecord
  acts_as_paranoid

  attr_accessor :reorder

  belongs_to :inventory
  belongs_to :user, optional: true
  belongs_to :component, optional: true
  belongs_to :part, optional: true
  belongs_to :material, optional: true

  validates :inventory_id, :loose_count, :unopened_boxes_count, presence: true
  validates :loose_count, :unopened_boxes_count, :extrapolated_count, numericality: { only_integer: true }

  def item
    if part_id.present?
      Part.with_deleted.find(part_id)
    elsif material_id.present?
      Material.with_deleted.find(material_id)
    else
      Component.with_deleted.find(component_id)
    end
  end

  def name
    item.name
  end

  def type
    if part_id.present?
      "part"
    elsif material_id.present?
      "material"
    else
      "component"
    end
  end

  def tech_names
    if item.technologies.map { |t| t.name }.empty?
      "not associated"
    else
      item.technologies.map { |t| t.name }.join(", ")
    end
  end

  def supplier
    item.supplier
  end

  def box_count
    item.quantity_per_box * unopened_boxes_count
  end

  def available
    loose_count + box_count
  end

  def diff_from_previous(field)
    # field == "loose" || "box"
    prev_inv = Inventory.where("date < ?", inventory.date).order(date: :desc).first

    if prev_inv.present?
      case type
      when "part"
        prev_item = prev_inv.counts.where(part: part.id).first
      when "material"
        prev_item = prev_inv.counts.where(material: material.id).first
      when "component"
        prev_item = prev_inv.counts.where(component: component.id).first
      end
    end

    old_loose = prev_item.present? ? prev_item.loose_count : 0
    old_box   = prev_item.present? ? prev_item.unopened_boxes_count : 0

    if field == "loose"
      val = loose_count - old_loose
    elsif field == "box"
      val = unopened_boxes_count - old_box
    else
      val = 0
    end

    return val
  end

  def total
    if inventory.completed_at == nil
      "Not Finalized"
    else
      available + extrapolated_count
    end
  end

  def sort_by_user
    if user_id.present?
      1
    else
      0
    end
  end

  def reorder?
    answer = false
    if type != "component" && available < item.minimum_on_hand
      answer = true
    end
    answer
  end

  def can_produce
    if available == 0
      0
    else
      available / item.per_technology
    end
  end

  def weeks_to_out
    if available == 0
      0
    else
      mpr = item.technology.present? ? item.technology.monthly_production_rate : 0
      can_produce / ( mpr / 4.0 )
    end
  end

end
