# frozen_string_literal: true

class AddOrderingInfoToPartsAndMaterials < ActiveRecord::Migration[5.2]
  def change
    add_column :parts, :last_ordered_at, :datetime
    add_column :parts, :last_ordered_quantity, :integer
    add_column :parts, :last_received_at, :datetime
    add_column :parts, :last_received_quantity, :integer

    add_column :materials, :last_ordered_at, :datetime
    add_column :materials, :last_ordered_quantity, :integer
    add_column :materials, :last_received_at, :datetime
    add_column :materials, :last_received_quantity, :integer
  end
end
