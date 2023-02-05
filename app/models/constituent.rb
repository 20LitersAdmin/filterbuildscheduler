# frozen_string_literal: true

class Constituent < ApplicationRecord
  has_many :constituent_emails, foreign_key: :constituent_id
  has_many :constituent_phones, foreign_key: :constituent_id

  alias_attribute :emails, :constituent_emails
  alias_attribute :phones, :constituent_phones

  scope :with_primary_email, -> { where.not(primary_email: nil) }
  scope :with_primary_phone, -> { where.not(primary_phone: nil) }

  def self.latest_update_date
    all.order(updated_at: :desc).limit(1).first.updated_at
  end

  def self.last_modified
    (latest_update_date - 10.days).iso8601
  end
end
