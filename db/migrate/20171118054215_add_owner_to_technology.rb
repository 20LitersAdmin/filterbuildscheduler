class AddOwnerToTechnology < ActiveRecord::Migration[5.1]
  def change
    add_column :technologies, :owner, :string
  end
end
