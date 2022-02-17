# frozen_string_literal: true

class AddGoalRemainderToTechnology < ActiveRecord::Migration[6.1]
  def change
    add_column :technologies, :goal_remainder, :integer, default: 0
  end
end
