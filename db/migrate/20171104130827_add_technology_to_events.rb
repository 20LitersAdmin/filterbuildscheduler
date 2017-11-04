class AddTechnologyToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :technology_id, :integer
    add_foreign_key :events, :technologies
  end
end
