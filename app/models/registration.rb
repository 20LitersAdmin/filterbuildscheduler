# frozen_string_literal: true

class Registration < ApplicationRecord
  include Discard::Model
  include ActiveModel::Dirty

  belongs_to :user
  belongs_to :event

  # accept_waiver: form field to pass to user.accepted_waiver_on
  # form_source: a form field that handles page redirects based on values: "admin", "self", "anon"
  # email_opt_out: event#edit form field to pass to user.email_opt_out
  attr_accessor :accept_waiver, :email_opt_out, :form_source

  validates :guests_registered, :guests_attended, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true

  # RailsAdmin "active" is better than "kept"
  scope :active, -> { kept }

  scope :attended,              -> { where(attended: true) }

  scope :builders,              -> { where(leader: false) }
  scope :future,
        -> {
          select('registrations.*')
            .joins(:event)
            .where('events.discarded_at IS NULL')
            .where('events.start_time > ?', Time.now)
        }
  scope :leaders,               -> { where(leader: true) }

  scope :ordered_by_user_lname, -> { includes(:user).order('users.lname') }
  scope :past,
        -> {
          select('registrations.*')
            .joins(:event)
            .where('events.discarded_at IS NULL')
            .where('events.start_time < ?', Time.now)
        }
  scope :pre_reminders, -> { where(reminder_sent_at: nil) }

  def human_date
    created_at.strftime('%-m/%-d/%Y %H:%M')
  end

  def role
    leader? ? 'leader' : 'builder'
  end

  def total_registered
    guests_registered + 1
  end

  def total_attended
    return 0 unless attended?

    guests_attended + 1
  end

  # RegistrationsController line 69
  def waiver_accepted?
    user.signed_waiver_on?
  end

  def send_to_crm
    return if !attended? && user.reload.email_opt_out?

    BloomerangJob.perform_later(:buildscheduler, :create_from_registration, self, interaction_type: :attended_event)
  end

  ## Bloomerang
  def attended_event_interaction(constituent_id)
    subject = leader? ? 'Led' : 'Attended'
    subject += ' filter build event'
    note = "#{event.title} (#{event.format_time_slim})"
    note += "\nBrought #{guests_attended} #{'guest'.pluralize(guests_attended)}" if guests_attended.positive?

    {
      'AccountId': constituent_id.to_i,
      'Date': event.end_time.to_date.iso8601,
      'Channel': 'Other',
      'Purpose': 'VolunteerActivity',
      'Subject': subject,
      'Note': note,
      'IsInbound': true
    }.as_json
  end

  def pass_email_opt_out_to_user
    user.update_columns(email_opt_out:)
  end
end
