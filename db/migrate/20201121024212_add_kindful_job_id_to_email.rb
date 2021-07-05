# frozen_string_literal: true

class AddKindfulJobIdToEmail < ActiveRecord::Migration[6.0]
  def change
    add_column :emails, :kindful_job_id, :string, array: true
  end
end
