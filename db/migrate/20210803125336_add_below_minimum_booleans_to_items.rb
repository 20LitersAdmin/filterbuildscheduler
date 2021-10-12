# frozen_string_literal: true

class AddBelowMinimumBooleansToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :materials,    :below_minimum, :boolean, null: false, default: false
    add_column :parts,        :below_minimum, :boolean, null: false, default: false
    add_column :components,   :below_minimum, :boolean, null: false, default: false
    add_column :technologies, :below_minimum, :boolean, null: false, default: false

    add_column :technologies, :minimum_on_hand, :integer, default: 0, null: false
    add_column :components,   :minimum_on_hand, :integer, default: 0, null: false
  end
end
