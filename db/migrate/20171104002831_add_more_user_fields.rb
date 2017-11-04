class AddMoreUserFields < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :is_archived, :boolean, default: false
    add_column :users, :signed_consent_form_on, :date
    add_column :users, :qualified_technology_id, :integer, array: true, default: []
    add_column :users, :primary_location_id, :integer
  end
end
