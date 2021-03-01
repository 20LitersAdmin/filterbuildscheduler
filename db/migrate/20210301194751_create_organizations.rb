# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :name, index: true
      t.string :email, index: true

      t.timestamps
    end

    add_column :emails, :organization, :boolean, default: false, null: false
  end
end
