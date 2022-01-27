# frozen_string_literal: true

class Setup < ApplicationRecord
  belongs_to :event
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_and_belongs_to_many :users

  validates_presence_of :event_id, :creator_id, :date

  validate :date_must_be_before_event, if: :dates_present?

  scope :pre_reminders, -> { where(reminder_sent_at: nil) }
  scope :days_from_now, ->(num) { where(date: (Time.now + num.days).beginning_of_day..(Time.now + num.days).end_of_day) }

  def crew
    if users.any?
      users.pluck(:fname).to_sentence
    else
      'NO ONE'
    end
  end

  def in_the_future?
    return false unless date.present?

    date > Time.zone.now
  end

  def summary
    if date.to_date == event.start_time.to_date
      "Setup on #{date.strftime('%a, %-m/%-d')} at #{date.strftime('%-l:%M%P')} for Filter Build at #{event.start_time.strftime('%-l:%M%P')} "
    else
      "Setup on #{date.strftime('%a, %-m/%-d')} at #{date.strftime('%-l:%M%P')} for #{event.start_time.strftime('%-m/%-d')} Filter Build"
    end
  end

  def end_time
    return unless date.present?

    date + 1.hour
  end

  private

  def dates_present?
    date.present? &&
      event&.start_time.present?
  end

  def date_must_be_before_event
    errors.add(:date, 'Must be before event') if event.start_time < date
  end
end
