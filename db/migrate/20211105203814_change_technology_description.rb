# frozen_string_literal: true

class ChangeTechnologyDescription < ActiveRecord::Migration[6.1]
  def change
    rename_column :technologies, :description, :public_description
    add_column :technologies, :description, :text
  end
end
