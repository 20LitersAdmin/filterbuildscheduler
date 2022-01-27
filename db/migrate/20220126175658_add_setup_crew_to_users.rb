# frozen_string_literal: true

class AddSetupCrewToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_setup_crew, :boolean, default: false, null: false
  end
end
