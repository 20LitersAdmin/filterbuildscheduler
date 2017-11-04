class Technology < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :users

  def leaders
    users.where(is_leader: true)
  end
end
