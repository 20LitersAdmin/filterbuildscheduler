# frozen_string_literal: true

class AddRolesToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_scheduler, :boolean, default: false
    add_column :users, :is_data_manager, :boolean, default: false
    add_column :users, :is_oauth_admin, :boolean, default: false
  end
end
