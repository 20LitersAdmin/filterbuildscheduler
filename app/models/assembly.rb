# frozen_string_literal: true

class Assembly < ApplicationRecord
  belongs_to :combination, polymorphic: true
  belongs_to :item, polymorphic: true
end
