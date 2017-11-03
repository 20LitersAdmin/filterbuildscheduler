class CreateRegistrations < ActiveRecord::Migration[5.1]
  def change
    create_table :registrations do |t|
      t.integer :user_id, null: false
      t.integer :event_id, null: false
      t.boolean :attended
      t.boolean :leader, default: false
      t.integer :guests_registered, default: 0
      t.integer :guests_attended, default: 0
      t.string  :accomodations, default: ""
    end
  end
end
