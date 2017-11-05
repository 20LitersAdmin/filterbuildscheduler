class AddConstraintToTechnologyOnEvent < ActiveRecord::Migration[5.1]
  def change
  	change_column_null :events, :technology_id, false
  end
end
