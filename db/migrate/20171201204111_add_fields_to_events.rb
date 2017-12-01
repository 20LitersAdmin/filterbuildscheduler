class AddFieldsToEvents < ActiveRecord::Migration[5.1]
  def change
    change_table :events do |t|
      t.string :contact_name
      t.string :contact_email
    end
  end
end
