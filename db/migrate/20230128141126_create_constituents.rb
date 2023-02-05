# frozen_string_literal: true

class CreateConstituents < ActiveRecord::Migration[6.1]
  def change
    create_table :constituents do |t|
      # t.bigint :bloomerang_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :primary_email
      t.string :primary_phone
      t.timestamps
    end

    create_table :constituent_emails do |t|
      t.string :value, null: false
      t.integer :constituent_id
      t.boolean :is_primary, null: false, default: false
      t.string :email_type
    end

    create_table :constituent_phones do |t|
      t.string :value, null: false
      t.integer :constituent_id
      t.boolean :is_primary, null: false, default: false
      t.string :phone_type
    end
  end
end
