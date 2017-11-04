class CreateLocations < ActiveRecord::Migration[5.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :map_url
      t.string :photo_url
      t.string :instructioons
      t.timestamps
    end

    add_column :events, :location_id, :integer, null: false
  end
end
