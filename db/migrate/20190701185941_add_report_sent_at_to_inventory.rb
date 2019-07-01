class AddReportSentAtToInventory < ActiveRecord::Migration[5.2]
  def change
    add_column :inventories, :report_sent_at, :datetime
  end
end
