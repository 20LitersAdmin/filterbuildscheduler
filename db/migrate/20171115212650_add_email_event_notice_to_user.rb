class AddEmailEventNoticeToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :send_notification_emails, :boolean, default: false
  end
end
