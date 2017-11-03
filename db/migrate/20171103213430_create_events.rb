class CreateEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :events do |t|
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :title, null: false
      t.string :description
      t.integer :min_registrations
      t.integer :max_registrations
      t.integer :min_leaders
      t.integer :max_leaders

      t.timestamps
    end
  end
end
