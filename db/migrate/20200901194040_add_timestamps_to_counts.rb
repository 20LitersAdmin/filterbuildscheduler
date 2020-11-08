# frozen_string_literal: true

class AddTimestampsToCounts < ActiveRecord::Migration[5.2]
  def change
    add_column :counts, :created_at, :datetime
    add_column :counts, :updated_at, :datetime, index: true

    Inventory.all.each do |inv|
      @created = inv.created_at
      @updated = inv.updated_at
      inv.counts.update_all(created_at: @created, updated_at: @updated)
    end

    change_column_null :counts, :created_at, false
    change_column_null :counts, :updated_at, false
  end
end
