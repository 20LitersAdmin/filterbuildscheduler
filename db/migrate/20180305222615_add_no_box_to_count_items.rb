class AddNoBoxToCountItems < ActiveRecord::Migration[5.1]
  def change
    add_column :parts, :only_loose, :boolean, default: false
    add_column :materials, :only_loose, :boolean, default: false
    add_column :components, :only_loose, :boolean, default: false
  end
end
