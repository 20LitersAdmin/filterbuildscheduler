# frozen_string_literal: true

class AddDescriptionToParts < ActiveRecord::Migration[5.2]
  def change
    add_column :parts, :description, :text
    add_column :components, :description, :text
    add_column :materials, :description, :text

    remove_column :components, :common_id
  end
end
