# frozen_string_literal: true

class Supplier < ApplicationRecord
  acts_as_paranoid
  require 'uri'

  has_many :parts
  has_many :materials

  validates :name, presence: true
  validate :valid_url?
  validates :email, :poc_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true

  # scope :active, -> { where(deleted_at: nil) }

  def valid_url?
    # Allow nil
    if url.nil?
      return true
    end

    parsed_url = URI.parse(url)

    case
    when parsed_url.host.nil?
      errors.add(:url, "Bad URL")
      false
    when parsed_url.host.length - parsed_url.host.gsub('.','').length > 3
      errors.add(:url, "Bad URL")
      false
    when parsed_url.scheme != "http" && parsed_url.scheme != "https"
      errors.add(:url, "Must include http:// or https://")
      false
    else
      true
    end
  end

  def related_items(counts)
    ary = []
    counts.each do |c|
      if c.supplier == self
        ary << c
      end
    end
    ary
  end
end
