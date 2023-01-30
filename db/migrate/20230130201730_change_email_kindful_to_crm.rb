# frozen_string_literal: true

class ChangeEmailKindfulToCrm < ActiveRecord::Migration[6.1]
  def change
    rename_column :emails, :sent_to_kindful_on, :sent_to_crm_on
    rename_column :emails, :kindful_job_id, :crm_job_id
    rename_column :emails, :matched_emails, :matched_constituents
    add_column :emails, :direction, :string
    add_column :emails, :channel, :string, default: 'Email'
  end
end
