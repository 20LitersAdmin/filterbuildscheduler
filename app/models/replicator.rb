# frozen_string_literal: true

class Replicator
  include ActiveModel::Model

  attr_accessor :event_id
  attr_accessor :start_time
  attr_accessor :end_time
  attr_accessor :frequency
  attr_accessor :occurrences
  attr_accessor :replicate_leaders
  attr_accessor :initiator

  # rubocop:disable UselessAssignment
  # rubocop:disable RedundantSelf
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity

  def go!
    morph_params
    check_for_errors

    return false if self.errors.any?

    base_event = Event.find(self.event_id)

    new_event_ids = []

    start_schedule = IceCube::Schedule.new(now = self.start_time)
    end_schedule = IceCube::Schedule.new(now = self.end_time)

    if self.frequency == 'monthly'
      start_schedule.add_recurrence_rule IceCube::Rule.monthly.count(self.occurrences)
      end_schedule.add_recurrence_rule IceCube::Rule.monthly.count(self.occurrences)
    else # 'weekly'
      start_schedule.add_recurrence_rule IceCube::Rule.weekly.count(self.occurrences)
      end_schedule.add_recurrence_rule IceCube::Rule.weekly.count(self.occurrences)
    end

    error_ary = []

    start_schedule.all_occurrences.each_with_index do |s, i|
      if s == base_event.start_time
        error_ary << { i => 'Duplicate event skipped' }
        next
      end

      event = base_event.dup

      event.tap do |e|
        e.start_time = s
        e.end_time = end_schedule.all_occurrences[i]
        e.attendance = 0
        e.boxes_packed = 0
        e.emails_sent = false
        e.reminder_sent_at = nil
        e.deleted_at = nil
      end

      event.valid?

      error_ary << { i => event.errors.messages } if event.errors.any?

      next if event.errors.any?

      event.save

      new_event_ids << event.reload.id

      next unless self.replicate_leaders && base_event.leaders_registered.any?

      base_event.leaders_registered.each do |base_reg|
        reg = base_reg.dup

        reg.tap do |r|
          r.event_id = event.id
          r.attended = false
          r.guests_registered = 0
          r.guests_attended = 0
          r.reminder_sent_at = nil
          r.deleted_at = nil
        end

        reg.valid?

        error_ary << { i => reg.errors.messages } if reg.errors.any?

        next if reg.errors.any?

        reg.save
        # RegistrationMailer.delay.created(reg.reload) unless reg.user.email_opt_out?
        RegistrationMailer.created(reg.reload).deliver_now! unless reg.user.email_opt_out?
      end
    end

    Rails.logger.warn error_ary if error_ary.any?

    events = Event.where(id: new_event_ids)

    # EventMailer.delay.replicated(events, initiator)
    EventMailer.replicated(events, initiator).deliver_now!

    true
  end

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
    self.start_time = Time.parse(self.start_time)
    self.end_time = Time.parse(self.end_time)
    self.occurrences = self.occurrences.to_i
    self.replicate_leaders = ActiveModel::Type::Boolean.new.cast(self.replicate_leaders)
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
