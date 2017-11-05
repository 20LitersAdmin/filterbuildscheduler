class AddAttendanceToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :attendance, :integer
  end
end
