class Technology < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :users
  has_and_belongs_to_many :materials

  has_many :extrapolate_technology_components, dependent: :destroy, inverse_of: :technology
  has_many :components, through: :extrapolate_technology_components
  accepts_nested_attributes_for :extrapolate_technology_components, allow_destroy: true

  has_many :extrapolate_technology_parts, dependent: :destroy, inverse_of: :technology
  has_many :parts, through: :extrapolate_technology_parts
  accepts_nested_attributes_for :extrapolate_technology_parts, allow_destroy: true

  def leaders
    users.where(is_leader: true)
  end

  def primary_component
    # find the component related to this technology that represents the completed tech
    self.components.where(completed_tech: true).first
  end
end
