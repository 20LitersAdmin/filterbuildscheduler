class Technology < ApplicationRecord
  has_and_belongs_to_many :users

  def leaders
    users.where(is_leader: true)
  end
end
