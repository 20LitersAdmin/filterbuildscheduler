# frozen_string_literal: true

class AddTechologiesToInventory < ActiveRecord::Migration[6.1]
  def change
    add_column :inventories, :technologies, :string, array: true, default: []
  end
end
