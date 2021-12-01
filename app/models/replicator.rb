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
                :user

  def go!
    check_for_errors
    return false if errors.any?

    morph_params

    base_event = Event.find(event_id)

    error_ary = []
    replicated_events = []

    occurrences.times do |indx|
      starting = start_time + indx.public_send(interval.to_sym)
      ending = end_time + indx.public_send(interval.to_sym)

      if starting == base_event.start_time
        error_ary << { indx => 'Duplicate event skipped' }
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
        evt.technologies_built = 0
        evt.emails_sent = false
        evt.reminder_sent_at = nil
        evt.discarded_at = nil
      end

      event.valid?

      if event.errors.any?
        error_ary << { event.object_id => event.errors.messages }
        next
      end

      event.save

      replicated_events << event.reload

      # auto-register leaders
      event.registrations << base_event.registrations.leaders if replicate_leaders
    end

    Rails.logger.warn error_ary if error_ary.any?

    EventMailer.replicated(replicated_events, user).deliver_later

    true
  end

  # called by EventsController#replicate_occurences
  def date_array
    self.interval = frequency == 'monthly' ? 'months' : 'weeks'

    ary = []

    occurrences.times do |idx|
      starting = start_time + idx.public_send(interval.to_sym)
      ending = end_time + idx.public_send(interval.to_sym)

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
    self.start_time = Time.parse(start_time).utc if start_time.instance_of?(String)
    self.end_time = Time.parse(end_time).utc if end_time.instance_of?(String)
    self.occurrences = occurrences.to_i if occurrences.instance_of?(String)
    self.replicate_leaders = ActiveModel::Type::Boolean.new.cast(replicate_leaders) if replicate_leaders.instance_of?(String)
    self.interval = frequency == 'monthly' ? 'months' : 'weeks'
  end

  def check_for_errors
    errors.add(:frequency, message: "must be either 'weekly' or 'monthly'") unless %w[monthly weekly].include?(frequency)
    errors.add(:occurrences, message: 'must be present and positive') unless occurrences.to_i.positive?
    errors.add(:event_id, message: 'must be present') if event_id.blank?
    errors.add(:start_time, message: 'must be present') if start_time.blank?
    errors.add(:end_time, message: 'must be present') if end_time.blank?
    errors.add(:user, message: 'must be present') if user.blank?

    errors.add(:replicate_leaders, message: 'must be either true or false') unless [true, false, 'true', 'false', 0, 1, nil].include? replicate_leaders
  end
end
