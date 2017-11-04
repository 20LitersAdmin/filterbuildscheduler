class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :event
  scope :registered_as_leader, -> {where(leader: true)}
  delegate :waiver_accepted, to: :user, prefix: :false
  attr_accessor :waiver_accepted

end
