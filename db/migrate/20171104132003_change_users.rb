class ChangeUsers < ActiveRecord::Migration[5.1]
  def change
    change_table :users do |t|
    	t.remove :name
    	t.string :fname
    	t.string :lname
    end
  end
end
