# frozen_string_literal: true

class AddImpactResultsToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :impact_results, :integer, default: 0, null: false
  end
end
