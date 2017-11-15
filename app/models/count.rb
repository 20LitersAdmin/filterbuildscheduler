class Count < ApplicationRecord
  acts_as_paranoid

  belongs_to :inventory
  has_and_belongs_to_many :components
  has_and_belongs_to_many :parts
  has_and_belongs_to_many :materials
end
