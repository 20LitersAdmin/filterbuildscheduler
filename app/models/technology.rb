class Technology < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :users
  has_and_belongs_to_many :materials

  has_many :extrapolate_technology_components, dependent: :destroy
  has_many :components, through: :extrapolate_technology_components

  has_many :extrapolate_technology_parts, dependent: :destroy
  has_many :parts, through: :extrapolate_technology_parts

  def leaders
    users.where(is_leader: true)
  end
end
