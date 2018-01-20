class AddDefaultToEventAttendance < ActiveRecord::Migration[5.1]
  def change

    change_column_default :events, :attendance, 0
  end
end
