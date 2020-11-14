# frozen_string_literal: true

class CreateOauthUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :oauth_users do |t|
      t.string   :name
      t.string   :email
      t.string   :oauth_id
      t.string   :oauth_provider
      t.string   :oauth_token
      t.string   :oauth_refresh_token
      t.datetime :oauth_expires_at
      t.boolean  :sync_emails
      t.date     :last_email_sync
      t.string   :manual_query

      t.timestamps

      t.index :oauth_token, unique: true
      t.index :oauth_id,    unique: true
      t.index :email,       unique: true
    end
  end
end
