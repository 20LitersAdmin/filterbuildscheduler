# frozen_string_literal: true

class AddAvailabilityToUsersAndShortNameToTechnology < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :available_business_hours, :boolean, default: false, null: false
    add_column :users, :available_after_hours, :boolean, default: false, null: false

    add_column :technologies, :short_name, :string
  end
end
