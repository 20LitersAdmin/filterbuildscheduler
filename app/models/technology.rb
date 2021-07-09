# frozen_string_literal: true

class Technology < ApplicationRecord
  # TODO: Second deployment
  # include Discard::Model

  has_and_belongs_to_many :users

  # TODO: Second deployment
  # has_one_attached :image, dependent: :purge
  # has_one_attached :display_image, dependent: :purge

  has_many :assemblies, as: :combination, dependent: :destroy
  has_many :components, through: :assemblies, source: :item, source_type: 'Component'
  has_many :parts, through: :assemblies, source: :item, source_type: 'Part'

  # TODO: Second deployment
  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }

  # TODO: Second deployment
  # scope :active, -> { kept }
  scope :status_worthy, -> { where('monthly_production_rate > ?', 0).order(monthly_production_rate: 'desc') }
  scope :list_worthy, -> { where(list_worthy: true).order(:name) }
  scope :finance_worthy, -> { where.not(price_cents: 0).order(:name) }

  before_create :set_short_name, if: -> { short_name.nil? }

  def leaders
    users.where(is_leader: true)
  end

  # TODO: delete this
  def primary_component
    # find the component related to this technology that represents the completed tech
    components.where(completed_tech: true).first
  end

  def components
    uids = quantities.keys.grep(/^C[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('C', '').to_i }
    Component.where(id: ary)
  end

  # TODO: re-work this
  def cprice
    return Money.new(0) if primary_component.nil?

    primary_component.price
  end

  def event_tech_goals_within(num = 0)
    events = Event.future.within_days(num).where(technology: self)

    events.map(&:item_goal).sum
  end

  def materials
    uids = quantities.keys.grep(/^M[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('M', '').to_i }
    Material.where(id: ary)
  end

  def owner_acronym
    owner.gsub(/([a-z]|\s)/, '')
  end

  def parts
    uids = quantities.keys.grep(/^P[0-9]{3}/)
    ary = []
    uids.each { |u| ary << u.tr('P', '').to_i }
    Part.where(id: ary)
  end

  # TODO: re-work this
  def produceable
    inventory = Inventory.latest_completed

    # narrow the inventory counts down to just related to this technology
    counts_aoh = []
    inventory.counts.each do |c|
      counts_aoh << { type: c.type, id: c.item.id, name: c.name, produce_tech: c.can_produce_x_tech, required: c.item.required?, available: c.available, makeable: 0, produceable: 0 } if c.item.technology == self
    end

    mats_aoh = []
    parts_aoh = []
    comps_aoh = []
    counts_aoh.each do |hsh|
      case hsh[:type]
      when 'material'
        mats_aoh << { id: hsh[:id], available: hsh[:available], makeable: 0, produceable: 0 }
      when 'part'
        parts_aoh << { id: hsh[:id], available: hsh[:available], makeable: 0, produceable: 0 }
      when 'component'
        comps_aoh << { id: hsh[:id], available: hsh[:available], makeable: 0, produceable: 0 }
      end
    end

    # how many parts can be made from available materials?
    mats_aoh.each do |mat|
      parts_aoh.each do |part|
        emp = ExtrapolateMaterialPart.where(material_id: mat[:id]).where(part_id: part[:id]).first
        part[:makeable] = mat[:available] * emp.parts_per_material unless emp.nil?
        part[:produceable] = part[:available] + part[:makeable]
      end
    end

    # how many components can be made from available && makeable parts?
    parts_aoh.each do |part|
      comps_aoh.each do |comp|
        ecp = ExtrapolateComponentPart.where(part_id: part[:id]).where(component_id: comp[:id]).first
        comp[:makeable] = part[:produceable] / ecp.parts_per_component unless ecp.nil?
        comp[:produceable] = comp[:available] + comp[:makeable]
      end
    end

    # rebuild the counts_aoh with the new information && disregard the not required ones
    tech_items_aoh = []

    counts_aoh.each do |count|
      case count[:type]
      when 'material'
        count[:produceable] = count[:available]
      when 'part'
        parts_aoh.each do |part|
          if count[:id] == part[:id]
            count[:makeable] = part[:makeable]
            count[:produceable] = part[:produceable]
          end
        end
      when 'component'
        comps_aoh.each do |comp|
          if count[:id] == comp[:id]
            count[:makeable] = comp[:makeable]
            count[:produceable] = comp[:produceable]
          end
        end
      end
      tech_items_aoh << count if count[:required]
    end

    tech_items_aoh.sort_by! { |hsh| hsh[:produceable] }
  end

  def short_name_w_owner
    "#{short_name} (#{owner_acronym})"
  end

  # def superassemblies
  #   Assembly.none
  # end

  # def subassemblies
  #   # alias of assemblies, for tree traversal down
  #   assemblies
  # end

  private

  def set_short_name
    self.short_name = name.gsub(' Filter', '').gsub(' for Bucket', '')
  end
end
