# frozen_string_literal: true

class ChangeOauthUsersLastEmailSyncToDateTime < ActiveRecord::Migration[6.0]
  def up
    change_column :oauth_users, :last_email_sync, :datetime
    add_column :oauth_users, :oauth_error_message, :string
  end

  def down
    change_column :oauth_users, :last_email_sync, :date
    remove_column :oauth_users, :oauth_error_message, :string
  end
end
