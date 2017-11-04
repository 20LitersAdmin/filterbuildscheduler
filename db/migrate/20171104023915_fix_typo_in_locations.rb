class FixTypoInLocations < ActiveRecord::Migration[5.1]
  def change
  	rename_column :locations, :instructioons, :instructions
  end
end
