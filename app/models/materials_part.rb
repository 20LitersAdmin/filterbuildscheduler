# frozen_string_literal: true

class MaterialsPart < ApplicationRecord
  belongs_to :material
  belongs_to :part
end
