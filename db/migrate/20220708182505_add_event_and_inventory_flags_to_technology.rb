# frozen_string_literal: true

class AddEventAndInventoryFlagsToTechnology < ActiveRecord::Migration[6.1]
  def change
    add_column :technologies, :for_events, :boolean, default: true, null: false
    add_column :technologies, :for_inventories, :boolean, default: true, null: false
    remove_column :technologies, :list_worthy
  end
end
