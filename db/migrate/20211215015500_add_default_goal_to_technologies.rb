# frozen_string_literal: true

class AddDefaultGoalToTechnologies < ActiveRecord::Migration[6.1]
  def change
    add_column :technologies, :default_goal, :integer, default: 0, null: false
  end
end
