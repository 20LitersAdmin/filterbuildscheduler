# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :company_name, index: true
      t.string :email, index: true

      t.timestamps
    end
  end
end
