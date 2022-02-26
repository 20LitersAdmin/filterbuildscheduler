# frozen_string_literal: true

class AddBoxFieldsToItemables < ActiveRecord::Migration[6.1]
  def change
    add_column :technologies, :box_type, :string, default: 'box'
    add_column :components, :box_type, :string, default: 'box'
    add_column :materials, :box_type, :string, default: 'box'
    add_column :parts, :box_type, :string, default: 'box'

    add_column :technologies, :box_notes, :text
    add_column :components, :box_notes, :text
    add_column :materials, :box_notes, :text
    add_column :parts, :box_notes, :text
  end
end
