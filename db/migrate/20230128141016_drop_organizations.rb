# frozen_string_literal: true

class DropOrganizations < ActiveRecord::Migration[6.1]
  def change
    drop_table :organizations
  end
end
