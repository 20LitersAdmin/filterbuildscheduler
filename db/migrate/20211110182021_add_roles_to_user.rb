# frozen_string_literal: true

class AddRolesToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_scheduler, :boolean, default: false
    add_column :users, :is_data_manager, :boolean, default: false
    add_column :users, :is_oauth_admin, :boolean, default: false

    # manually add these new roles to specific users:
    # Chip
    User.find(1).update_columns(is_oauth_admin: true)
    # Amanda
    User.find(4).update_columns(is_oauth_admin: true, is_admin: false)
    # Bobbie
    User.find(1491).update_columns(is_scheduler: true, is_admin: false)
    # Andrea
    User.find(169).update_columns(is_data_manager: true, is_admin: false)
    # Tom Fields
    User.find(174).update_columns(does_inventory: true, is_admin: false)
    # Liz Jaspers
    User.find(14).update_columns(does_inventory: true, is_admin: false)
    # Andrew Vantimmeren - no changes

    # Greta - no longer active
    User.find(1366).update_columns(is_admin: false)
  end
end
