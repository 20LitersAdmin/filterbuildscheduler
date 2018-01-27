class AddPartialToCounts < ActiveRecord::Migration[5.1]
  def change
    # remove_column :counts, :partial
    
    add_column :counts, :partial_box, :boolean, default: false
    add_column :counts, :partial_loose, :boolean, default: false
  end
end
