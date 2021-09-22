# frozen_string_literal: true

class AddLeaderTypeAndNotesToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :leader_type, :integer
    add_column :users, :leader_notes, :string
  end
end
