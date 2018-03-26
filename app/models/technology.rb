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

  def produceable
    inventory = Inventory.latest

    count_ary = []

    inventory.counts.each do |c|
      if c.item.technology == self
        count_ary << { id: c.id, produceable: c.can_produce }
      end

      # Ignore the primary_component
      # Need to sub-loop over components.available == 0 and do the same: components.parts.each do |p| p.counts.latest.available / p.per_technology end
      # Need to ignore parts.available == 0 if parent component is not 0
    end

    # PROBLEM: binding.pry
    # > count_ids = count_ary.map { |a| a[:id] }
    # > Count.find(count_ids).map { |c| [c.item.name, c.available] }
    # [["Tubing 12-inch", 8008],
    #  ["3-inch assembled cartridges welded", 1875],
    #  ["3-inch assembled cartridges unwelded", 2150],
    #  ["Bags w/ Instructions VF100", 0],               ******************* Have bags, have instructions, so... can_produce needs to exist on components && parts.made_from_materials
    #  ["3-inch core with O-rings", 5144],
    #  ["Bucket Filter - VF100", 6706],
    #  ["Tubing - 2-inch", 2680],
    #  ["Shipping Box 20x20x20", 25],
    #  ["Rubber Washer large hole", 3669],
    #  ["Filter Housing Long (blue)", 19],
    #  ["Thin O-ring", 337],
    #  ["Syringes", 5389],
    #  ["Saddle - plastic (blue)", 4288],
    #  ["Bucket Filter Instructions", 64],
    #  ["Nut - plastic (blue)", 3600],
    #  ["Thick O-ring", 405],
    #  ["Hook - plastic (blue)", 5220],
    #  ["3-inch core", 240],
    #  ["Adaptor FGHT to 1/4-inch barbed", 21931],
    #  ["Rubber Washer beveled", 5578],
    #  ["Filter Housing Short (blue)", 0],          ******************* Yes, part is gone, but parent component is present
    #  ["Cartridge O-ring 40-mm ID", 0],            ******************* Yes, part is gone, but parent component is present
    #  ["Hose Clamp", 6329],
    #  ["1/2-inch O-ring (thick)", 12423],
    #  ["Plastic Bag 8x10", 1101],
    #  ["Rubber Washer small hole", 16602]]

    count_ary.sort_by!{ |hsh| hsh[:produceable] }.first[:produceable]

  end
end
