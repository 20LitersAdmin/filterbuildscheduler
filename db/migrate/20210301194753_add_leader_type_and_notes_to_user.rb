# frozen_string_literal: true

class AddLeaderTypeAndNotesToUser < ActiveRecord::Migration[6.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:users, :leader_type)
      add_column :users, :leader_type, :integer
      add_column :users, :leader_notes, :string
    end
  end
end
