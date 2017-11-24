class Technology < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :users

  has_many :extrapolate_technology_components
  has_many :components, through: :extrapolate_technology_components

  has_many :extrapolate_technology_parts
  has_many :parts, through: :extrapolate_technology_parts

  has_many :extrapolate_technology_materials
  has_many :materials, through: :extrapolate_technology_materials

  def leaders
    users.where(is_leader: true)
  end
end
