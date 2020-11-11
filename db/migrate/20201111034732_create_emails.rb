# frozen_string_literal: true

class CreateEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :emails do |t|
      t.belongs_to :oauth_user, null: false, foreign_key: true
      t.string :from
      t.string :to
      t.string :subject
      t.datetime :date
      t.text :body
      t.string :gmail_id, index: true
      t.string :message_id, index: true
      t.string :reference_ids, index: true
      t.timestamps
    end
  end
end
