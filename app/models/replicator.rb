# frozen_string_literal: true

class Replicator
  include ActiveModel::Model

  attr_accessor :event_id
  attr_accessor :start_time
  attr_accessor :end_time
  attr_accessor :frequency
  attr_accessor :interval
  attr_accessor :occurrences
  attr_accessor :replicate_leaders
  attr_accessor :initiator

  # rubocop:disable UselessAssignment
  # rubocop:disable RedundantSelf
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity

  def go!
    # test this out!!!

    morph_params
    check_for_errors

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
    start_schedule = IceCube::Schedule.new(now = self.start_time)
    end_schedule = IceCube::Schedule.new(now = self.end_time)

    if frequency == 'monthly'
      start_schedule.add_recurrence_rule IceCube::Rule.monthly.count(self.occurrences)
      end_schedule.add_recurrence_rule IceCube::Rule.monthly.count(self.occurrences)
    else # 'weekly'
      start_schedule.add_recurrence_rule IceCube::Rule.weekly.count(self.occurrences)
      end_schedule.add_recurrence_rule IceCube::Rule.weekly.count(self.occurrences)
    end

    ary = []

    start_schedule.all_occurrences.each_with_index do |s, i|
      hsh = { s: Time.parse(s.to_s).strftime('%a %-m/%-d/%y %-l:%M %P'), e: DateTime.parse(end_schedule.all_occurrences[i].to_s).strftime('%a %-m/%-d/%y %-l:%M %P') }
      ary << hsh
    end

    ary
  end

  def morph_params
    self.start_time = Time.parse(start_time).utc
    self.end_time = Time.parse(end_time).utc
    self.occurrences = self.occurrences.to_i
    self.replicate_leaders = ActiveModel::Type::Boolean.new.cast(self.replicate_leaders)
    self.interval = frequency == 'monthly' ? 'months' : 'weeks'
  end

  def check_for_errors
    errors.add(:frequency, :invalid, message: 'must be either "weekly" or "monthly"') unless %w[monthly weekly].include?(self.frequency)
    errors.add(:occurrences, :invalid, message: 'must be present and positive') unless self.occurrences.to_i.positive?
    errors.add(:event_id, :invalid, message: 'must be present') if self.event_id.blank?
    errors.add(:start_time, :invalid, message: 'must be present') if self.start_time.blank?
    errors.add(:end_time, :invalid, message: 'must be present') if self.end_time.blank?
    errors.add(:replicate_leaders, :invalid, message: 'must be boolean') unless [true, false].include?(self.replicate_leaders) || self.replicate_leaders.nil?
  end

  # rubocop:enable UselessAssignment
  # rubocop:enable RedundantSelf
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
