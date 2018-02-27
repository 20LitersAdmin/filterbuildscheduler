class AddDefaultsToMinOrder < ActiveRecord::Migration[5.1]
  def change

    change_column_default(:parts, :min_order, 1)
    change_column_default(:parts, :weeks_to_deliver, 1)
    change_column_default(:materials, :min_order, 1)
    change_column_default(:materials, :weeks_to_deliver, 1)
  end
end
