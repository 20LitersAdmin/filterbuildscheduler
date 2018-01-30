class AddCommentsToTechStuff < ActiveRecord::Migration[5.1]
  def change

    add_column :parts, :comments, :text
    add_column :materials, :comments, :text
    add_column :components, :comments, :text
    add_column :technologies, :comments, :text
  end
end
