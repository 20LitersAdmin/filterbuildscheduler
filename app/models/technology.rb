# frozen_string_literal: true

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

  scope :active, -> { where(deleted_at: nil) }
  scope :status_worthy, -> { where("monthly_production_rate > ?", 0).order(monthly_production_rate: "desc") }

  # fake scope
  def self.finance_worthy
    ary = []
    Technology.all.each do |technology|
      ary << technology if technology.price.positive?
    end
    ary
  end

  def leaders
    users.where(is_leader: true)
  end

  def primary_component
    # find the component related to this technology that represents the completed tech
    components.where(completed_tech: true).first
  end

  def price
    return Money.new(0) if primary_component.nil?
    
    primary_component.price
  end

  def short_name
    name.partition(" ").first
  end

  def event_tech_goals_within(num = 0)
    events = Event.future.within_days(num).where(technology: self)

    events.map(&:item_goal).sum
  end

  def owner_acronym
    owner.gsub(/([a-z]|\s)/,'')
  end

  def produceable
    inventory = Inventory.latest

    # narrow the inventory counts down to just related to this technology
    counts_aoh = []
    inventory.counts.each do |c|
      if c.item.technology == self
        counts_aoh << { type: c.type, id: c.item.id, name: c.name, produce_tech: c.can_produce_x_tech, required: c.item.required?, available: c.available, makeable: 0, produceable: 0 }
      end
    end

    mats_aoh = []
    parts_aoh = []
    comps_aoh = []
    counts_aoh.each do |hsh|
      case hsh[:type]
      when "material"
        mats_aoh << { id: hsh[:id], available: hsh[:available], makeable: 0, produceable: 0 }
      when "part"
        parts_aoh << { id: hsh[:id], available: hsh[:available], makeable: 0, produceable: 0 }
      when "component"
        comps_aoh << { id: hsh[:id], available: hsh[:available], makeable: 0, produceable: 0 }
      end
    end

    # how many parts can be made from available materials?
    mats_aoh.each do |mat|
      parts_aoh.each do |part|
        emp = ExtrapolateMaterialPart.where(material_id: mat[:id]).where(part_id: part[:id]).first
        if !emp.nil?
          part[:makeable] = mat[:available] *  emp.parts_per_material
        end
        part[:produceable] = part[:available] + part[:makeable]
      end
    end

    # how many components can be made from available && makeable parts?
    parts_aoh.each do |part|
      comps_aoh.each do |comp|
        ecp = ExtrapolateComponentPart.where(part_id: part[:id]).where(component_id: comp[:id]).first
        if !ecp.nil?
          comp[:makeable] = part[:produceable] / ecp.parts_per_component
        end
        comp[:produceable] = comp[:available] + comp[:makeable]
      end
    end

    # rebuild the counts_aoh with the new information && disregard the not required ones
    tech_items_aoh = []

    counts_aoh.each do |count|
      case count[:type]
      when "material"
        count[:produceable] = count[:available]
      when "part"
        parts_aoh.each do |part|
          if count[:id] == part[:id]
            count[:makeable] = part[:makeable]
            count[:produceable] = part[:produceable]
          end
        end
      when "component"
        comps_aoh.each do |comp|
          if count[:id] == comp[:id]
            count[:makeable] = comp[:makeable]
            count[:produceable] = comp[:produceable]
          end
        end
      end
      if count[:required]
        tech_items_aoh << count
      end
    end

    tech_items_aoh.sort_by! { |hsh| hsh[:produceable] }
  end

end
