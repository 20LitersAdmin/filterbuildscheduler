# frozen_string_literal: true

class AddGoalRemainderToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :components, :goal_remainder, :integer, default: 0

    add_column :parts, :goal_remainder, :integer, default: 0

    add_column :materials, :goal_remainder, :integer, default: 0
  end
end
