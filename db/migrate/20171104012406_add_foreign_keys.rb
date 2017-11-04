class AddForeignKeys < ActiveRecord::Migration[5.1]
  def change
  	add_foreign_key :registrations, :events
  	add_foreign_key :registrations, :users
  	add_foreign_key :events, :locations
  end
end
