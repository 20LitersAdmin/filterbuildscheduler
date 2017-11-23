class Count < ApplicationRecord
  acts_as_paranoid

  belongs_to :inventory
  belongs_to :user, optional: true
  belongs_to :component, optional: true
  belongs_to :part, optional: true
  belongs_to :material, optional: true

  def name
    if part_id.present?
      self.part.name
    elsif material_id.present?
      self.material.name
    elsif component_id.present?
      self.component.name
    else
      "UNKNOWN"
    end
  end
end
