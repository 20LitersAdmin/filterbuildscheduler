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
      part
    elsif material_id.present?
      material
    else
      component
    end
  end

  def name
    self.item.name
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
    if self.item.technologies.map { |t| t.name }.empty?
      "not associated"
    else
      self.item.technologies.map { |t| t.name }.join(", ")
    end
  end

  def box_count
    self.item.quantity_per_box * unopened_boxes_count
  end

  def available
    loose_count + box_count
  end

  def diff_from_previous(field)
    # field == "loose" || "box"
    prev_inv = Inventory.where("date < ?", self.inventory.date).order(date: :desc).first

    if prev_inv.present?
      case self.type
      when "part"
        prev = prev_inv.counts.where(part_id: self.part_id).first
      when "material"
        prev = prev_inv.counts.where(material_id: self.material_id).first
      when "component"
        prev = prev_inv.counts.where(component_id: self.component_id).first
      end

      if field == "loose"
        val = self.loose_count - prev.loose_count
      elsif field == "box"
        val = self.unopened_boxes_count - prev.unopened_boxes_count
      else
        val = 0
      end
    else
      if field == "loose"
        val = self.loose_count
      elsif field == "box"
        val = self.unopened_boxes_count
      else
        val = 0
      end
    end

    return val
  end

  def total
    if self.inventory.completed_at == nil
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
    @answer = false
    if self.type != "component" && self.available < self.item.minimum_on_hand
      @answer = true
    end
    @answer
  end
end
