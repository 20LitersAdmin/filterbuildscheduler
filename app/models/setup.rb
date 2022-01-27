# frozen_string_literal: true

class Setup < ApplicationRecord
  belongs_to :event
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_and_belongs_to_many :users

  validates_presence_of :event_id, :creator_id, :date

  validate :date_must_be_before_event

  def crew
    if users.any?
      users.pluck(:fname).to_sentence
    else
      'NO ONE'
    end
  end

  def summary
    if date.to_date == event.start_time.to_date
      "Setup on #{date.strftime('%a, %-m/%-d')} at #{date.strftime('%-l:%M%P')} for Filter Build at #{event.start_time.strftime('%-l:%M%P')} "
    else
      "Setup on #{date.strftime('%a, %-m/%-d')} for #{event.start_time.strftime('%-m/%-d')} Filter Build"
    end
  end

  def end_time
    date + 1.hour
  end

  private

  def date_must_be_before_event
    errors.add(:date, 'Must be before event') if event.start_time < date
  end
end
