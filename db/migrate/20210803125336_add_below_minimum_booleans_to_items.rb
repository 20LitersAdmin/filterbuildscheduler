# frozen_string_literal: true

class AddBelowMinimumBooleansToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :materials,    :below_minimum,        :boolean, null: false, default: false
    add_column :parts,        :below_minimum,        :boolean, null: false, default: false
  end
end
