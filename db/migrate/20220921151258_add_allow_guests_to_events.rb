# frozen_string_literal: true

class AddAllowGuestsToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :allow_guests, :boolean, default: true, null: false
  end
end
