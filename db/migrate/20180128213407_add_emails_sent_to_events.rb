class AddEmailsSentToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :emails_sent, :boolean, default: false
  end
end
