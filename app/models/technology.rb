class Technology < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :users
  has_and_belongs_to_many :components
  has_and_belongs_to_many :parts

  def leaders
    users.where(is_leader: true)
  end
end
