# frozen_string_literal: true

class CreateSetups < ActiveRecord::Migration[6.1]
  def change
    create_table :setups do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.references :creator, index: true, null: false, foreign_key: { to_table: :users }
      t.datetime :date

      t.timestamps
    end
  end

  create_join_table :setups, :users do |t|
    t.index %i[setup_id user_id], unique: true
    t.index %i[user_id setup_id], unique: true
  end
end
