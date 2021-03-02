# frozen_string_literal: true

class Organization < ApplicationRecord
  validates :company_name, :email, presence: true
end
