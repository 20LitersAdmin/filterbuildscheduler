# frozen_string_literal: true

class AddExtrapolateToInventories < ActiveRecord::Migration[6.1]
  def change
    add_column :inventories, :extrapolate, :boolean, default: false, null: false
  end
end
