class AddImpactsToTechnology < ActiveRecord::Migration[5.1]
  def change
    change_table :technologies do |t|
      t.integer :people, null: false, default: 0
      t.integer :lifespan_in_years, null: false, default: 0
      t.integer :liters_per_day, default: 0
    end
  end
end
