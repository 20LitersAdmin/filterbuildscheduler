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

  scope :status_worthy, -> { where("monthly_production_rate > ?", 0).order(monthly_production_rate: "desc") }

  def leaders
    users.where(is_leader: true)
  end

  def primary_component
    # find the component related to this technology that represents the completed tech
    components.where(completed_tech: true).first
  end

  def short_name
    name.partition(" ").first
  end

  def event_tech_goals_within(num = 0)
    events = Event.future.within_days(num).where(technology: self)

    events.map { |e| e.item_goal }.sum
  end
end
