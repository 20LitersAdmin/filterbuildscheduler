# frozen_string_literal: true

class AddListWorthyToTechnology < ActiveRecord::Migration[6.0]
  def change
    add_column :technologies, :list_worthy, :boolean, default: true, null: false
  end
end
