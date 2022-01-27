# frozen_string_literal: true

class Setup < ApplicationRecord
  belongs_to :event
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_and_belongs_to_many :users

  validates_presence_of :event_id, :creator_id, :date

  validate :date_must_be_before_event

  private

  def date_must_be_before_event
    errors.add(:date, 'Must be before event') if event.start_time < date
  end
end
