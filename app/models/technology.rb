class Technology < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :users

  has_many :extrapolate_technology_components, dependent: :destroy, inverse_of: :technology
  has_many :components, through: :extrapolate_technology_components
  accepts_nested_attributes_for :extrapolate_technology_components, allow_destroy: true

  has_many :extrapolate_technology_parts, dependent: :destroy, inverse_of: :technology
  has_many :parts, through: :extrapolate_technology_parts
  accepts_nested_attributes_for :extrapolate_technology_parts, allow_destroy: true

  has_many :extrapolate_technology_materials, dependent: :destroy, inverse_of: :technology
  has_many :materials, through: :extrapolate_technology_materials
  accepts_nested_attributes_for :extrapolate_technology_materials, allow_destroy: true

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

    tech_count_ids = []

    inventory.counts.each do |c|
      if c.item.technology == Technology.first && c.item.required?
        tech_count_ids << c.id
      end
    end

    mat_counts = inventory.counts.where(id: tech_count_ids).joins(:material)
    parts_can_be_built = []
    mat_counts.each do |c|
      parts_can_be_built << { part_id: c.material.parts.first.id, mat_produce: c.can_produce }
    end

    part_counts = inventory.counts.where(id: tech_count_ids).joins(:part)
    comps_can_be_built = []
    part_counts.each do |c|
      comps_can_be_built << { comp_id: c.part.components.first.id, part_id: c.part.id, part_produce: c.can_produce }
    end

    comp_counts = inventory.counts.where(id: tech_count_ids).joins(:component).where('components.completed_tech = ?', false)
    prime_can_be_built = []
    comp_counts.each do |c|
      prime_can_be_built << { prime_id: Technology.first.primary_component.id, comp_id: c.component.id, comp_produce: c.can_produce }
    end

    parts_can_be_built
    comps_can_be_built
    prime_can_be_built

    comps_can_be_built.each do |comps|
      parts_can_be_built.each do |parts|
        if parts[:part_id] == comps[:part_id]
        comps[:part_produce] += parts[:mat_produce]
        end
      end
    end


    # New strategy: traverse down and collect results
    # Primary_component > components > parts > materials
    # Primary_component > parts > materials
    # comp_count_ary << { id: c.id, produceable: c.can_produce }

    # Still need to:
    # Use the primary_component instead of the technology (c.item.technology is the problem, should be based on relation to primary_component)
    # Sub-loop over components.available == 0 and do the same: components.parts.each do |p| p.counts.latest.available / p.per_technology end
    # Ignore parts.available == 0 if parent component is not 0

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
    #  ["Shipping Box 20x20x20", 25],                   ******************* Not required to make the primary_component
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

  end

end
