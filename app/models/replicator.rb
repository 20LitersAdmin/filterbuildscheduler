# frozen_string_literal: true

class Replicator
  include ActiveModel::Model

  attr_accessor :event_id,
                :start_time,
                :end_time,
                :frequency,
                :interval,
                :occurrences,
                :replicate_leaders,
                :initiator

  # rubocop:disable RedundantSelf
  # rubocop:disable Metrics/CyclomaticComplexity

  def initialize(*args)
    super
    morph_params
    check_for_errors
  end

  def go!
    return false if errors.any?

    base_event = Event.find(event_id)

    new_event_ids = []
    error_ary = []

    occurrences.times do |idx|
      starting = start_time + idx.send(interval.to_sym)
      ending = end_time + idx.send(interval.to_sym)

      if starting == base_event.start_time
        error_ary << { idx => 'Duplicate event skipped' }
        next
      end

      # handle the edge cases of recurrences that span daylight savings time changes
      unless starting.localtime.hour == start_time.localtime.hour
        # force the *new* times to match the hour value of the *old* times
        starting = starting.localtime + (start_time.localtime.hour - starting.localtime.hour).hours
        ending = ending.localtime + (end_time.localtime.hour - ending.localtime.hour).hours
      end

      event = base_event.dup

      event.tap do |evt|
        evt.start_time = starting
        evt.end_time = ending
        evt.attendance = 0
        evt.boxes_packed = 0
        evt.emails_sent = false
        evt.reminder_sent_at = nil
        evt.deleted_at = nil
      end

      event.valid?

      if event.errors.any?
        error_ary << { event.object_id => event.errors.messages }
        next
      end

      event.save

      new_event_ids << event.reload.id
    end

    Rails.logger.warn error_ary if error_ary.any?

    events = Event.where(id: new_event_ids)

    # EventMailer.delay.replicated(events, initiator)
    EventMailer.replicated(events, initiator).deliver_now!

    true
  end

  # called by events_controller#replicate_occurences
  def date_array
    self.interval = frequency == 'monthly' ? 'months' : 'weeks'

    ary = []

    occurrences.times do |idx|
      starting = start_time + idx.send(interval.to_sym)
      ending = end_time + idx.send(interval.to_sym)

      # handle the edge cases of recurrences that span daylight savings time changes
      unless starting.localtime.hour == start_time.localtime.hour
        # force the *new* times to match the hour value of the *old* times
        starting = starting.localtime + (start_time.localtime.hour - starting.localtime.hour).hours
        ending = ending.localtime + (end_time.localtime.hour - ending.localtime.hour).hours
      end

      hsh = { s: starting.strftime('%a %-m/%-d/%y %-l:%M %P'), e: ending.strftime('%a %-m/%-d/%y %-l:%M %P') }
      ary << hsh
    end

    ary
  end

  def morph_params
    self.start_time = Time.parse(start_time).utc if start_time.class == String
    self.end_time = Time.parse(end_time).utc if end_time.class == String
    self.occurrences = self.occurrences.to_i if occurrences.class == String
    self.replicate_leaders = ActiveModel::Type::Boolean.new.cast(self.replicate_leaders) if replicate_leaders.class == String
    self.interval = frequency == 'monthly' ? 'months' : 'weeks'
    self
  end

  def check_for_errors
    errors.add(:frequency, :invalid, message: "must be either 'weekly' or 'monthly'") unless %w[monthly weekly].include?(self.frequency)
    errors.add(:occurrences, :invalid, message: 'must be present and positive') unless self.occurrences.to_i.positive?
    errors.add(:event_id, :invalid, message: 'must be present') if self.event_id.blank?
    errors.add(:start_time, :invalid, message: 'must be present') if self.start_time.blank?
    errors.add(:end_time, :invalid, message: 'must be present') if self.end_time.blank?
    errors.add(:replicate_leaders, :invalid, message: 'must be boolean') unless [true, false].include?(self.replicate_leaders)
  end

  # rubocop:enable RedundantSelf
  # rubocop:enable Metrics/CyclomaticComplexity
end
