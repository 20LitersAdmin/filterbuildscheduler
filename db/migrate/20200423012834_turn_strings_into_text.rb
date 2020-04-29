# frozen_string_literal: true

class TurnStringsIntoText < ActiveRecord::Migration[5.2]
  def change
    change_column :technologies, :description, :text
    change_column :events, :description, :text
    change_column :locations, :instructions, :text
    change_column :registrations, :accommodations, :text
  end
end
