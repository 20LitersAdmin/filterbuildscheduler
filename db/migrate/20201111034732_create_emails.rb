# frozen_string_literal: true

class CreateEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :emails do |t|
      t.belongs_to :oauth_user, null: false, foreign_key: true
      t.string :from, array: true
      t.string :to, array: true
      t.string :subject
      t.datetime :datetime
      t.text :body
      t.text :snippet
      t.string :gmail_id, index: true
      t.string :message_id, index: true
      t.datetime :sent_to_kindful_on
      t.string :matched_emails, array: true
      t.timestamps
    end
  end
end
