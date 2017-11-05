class CreateJoinTableUserTechnology < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :qualified_technology_id

    create_join_table :users, :technologies do |t|
      t.index [:user_id, :technology_id]
      t.index [:technology_id, :user_id]
    end
  end
end
