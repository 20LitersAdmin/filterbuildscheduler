# frozen_string_literal: true

class ChangeAdminEmailPreferences < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :send_notification_emails, :send_event_emails
  end
end
