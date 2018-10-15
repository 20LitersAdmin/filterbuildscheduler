class AddRemindersSentToEventsAndRegistrations < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :reminder_sent_at, :datetime
    add_column :registrations, :reminder_sent_at, :datetime
  end
end
