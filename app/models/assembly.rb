# frozen_string_literal: true

class Assembly < ApplicationRecord
  belongs_to :combination, polymorphic: true
  belongs_to :item, polymorphic: true

  before_save :assign_priority

  scope :prioritized, -> { order(:priority, :item_id) }

  def has_sub_items?
    return false if item_type == 'Part'

    Assembly.where(combination: item).any?
  end

  def has_sub_components?
    return false if item_type == 'Part'

    Assembly.where(combination: item, item_type: 'Component').any?
  end

  def sub_assemblies
    return Assembly.none if item_type == 'Part'

    Assembly.where(combination: item)
  end

  def sub_component_assemblies
    return Assembly.none if item_type == 'Part'

    Assembly.where(combination: item, item_type: 'Component')
  end

  def combination_uid
    "#{combination_type[0]}#{combination_id.to_s.rjust(3, 0.to_s)}"
  end

  def item_uid
    "#{item_type[0]}#{item_id.to_s.rjust(3, 0.to_s)}"
  end

  # TODO: temporary clean-up method
  # remove duplicates where items exist under this Component AND under a subcomponent of this component
  def remove_duplicates!
    return false unless has_sub_components?

    item_ids = []
    sub_component_assemblies.each do |sca|
      item_ids << sca.item.subassemblies.pluck(:item_id)
    end

    combination_delete = Assembly.where(combination: combination, item: item_ids.flatten)
    # combination_delete_uids = combination_delete.map(&:item_uid)

    item_delete = Assembly.where(combination: item, item: item_ids.flatten)
    # item_delete_uids = item_delete.map(&:item_uid)

    # puts 'Confirmation required.'
    # puts "Remove these items from #{combination_uid}: #{combination_delete_uids}"
    # puts "Remove these items from #{item_uid}: #{item_delete_uids}"
    # puts 'Y to proceed, any other key to cancel'
    # input = gets.strip

    # return 'Bailed out!' unless %w[Y y].include?(input)

    combination_delete.destroy_all
    item_delete.destroy_all
    # puts 'Done!'
  end

  private

  def assign_priority
    self.priority = Constants::Assembly::PRIORITY[item_type]
  end
end
