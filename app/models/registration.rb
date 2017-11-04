class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :event
  scope :registered_as_leader, -> {where(leader: true)}
end
