class RenameAccommodations < ActiveRecord::Migration[5.1]
  def change
    rename_column :registrations, :accomodations, :accommodations
  end
end
