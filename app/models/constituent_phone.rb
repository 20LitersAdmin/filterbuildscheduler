# frozen_string_literal: true

class ConstituentPhone < ApplicationRecord
  belongs_to :constituent

  scope :only_primaries, -> { where(is_primary: true) }
end
