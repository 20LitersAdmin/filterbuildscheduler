class Count < ApplicationRecord
  acts_as_paranoid

  belongs_to :inventory
  belongs_to :user, optional: true
  belongs_to :component, optional: true
  belongs_to :part, optional: true
  belongs_to :material, optional: true

  validates :inventory_id, :loose_count, :unopened_boxes_count, presence: true, numericality: { only_integer: true }

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

  def total
    # available + ( # per unit -- is a component? * # of completed un-boxed units)
    "TBD"
  end

  def sort_by_user
    if user_id.present?
      1
    else
      0
    end
  end

end
