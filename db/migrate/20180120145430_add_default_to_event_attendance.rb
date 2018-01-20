class AddDefaultToEventAttendance < ActiveRecord::Migration[5.1]
  def change

    change_column_default :events, :attendance, default: 0
  end
end
