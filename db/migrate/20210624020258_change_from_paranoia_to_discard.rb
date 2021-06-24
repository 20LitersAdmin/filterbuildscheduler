class ChangeFromParanoiaToDiscard < ActiveRecord::Migration[6.1]
  def change
    rename_column :components, :deleted_at, :discarded_at
    rename_column :events, :deleted_at, :discarded_at
    rename_column :locations, :deleted_at, :discarded_at
    rename_column :materials, :deleted_at, :discarded_at
    rename_column :parts, :deleted_at, :discarded_at
    rename_column :registrations, :deleted_at, :discarded_at
    rename_column :suppliers, :deleted_at, :discarded_at
    rename_column :technologies, :deleted_at, :discarded_at
    rename_column :users, :deleted_at, :discarded_at

    remove_column :counts, :deleted_at, type: :datetime
    remove_column :inventories, :deleted_at, type: :datetime
  end
end
