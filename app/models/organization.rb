# frozen_string_literal: true

class Organization < ApplicationRecord
  validates :name, :email, presence: true
end
