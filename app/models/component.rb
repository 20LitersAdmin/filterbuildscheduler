class Component < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :parts
  has_and_belongs_to_many :technologies
  has_and_belongs_to_many :counts

  def id_ary
    map { |o| o.id }
  end
end
