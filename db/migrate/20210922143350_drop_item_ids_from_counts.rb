# frozen_string_literal: true

class DropItemIdsFromCounts < ActiveRecord::Migration[6.1]
  def change
    remove_column :counts, :component_id
    remove_column :counts, :material_id
    remove_column :counts, :part_id
    remove_column :counts, :extrapolated_count
  end
end
