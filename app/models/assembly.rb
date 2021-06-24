# frozen_string_literal: true

class Assembly < ApplicationRecord
  belongs_to :combinations, polymorphic: true
  belongs_to :items, polymorphic: true
end
