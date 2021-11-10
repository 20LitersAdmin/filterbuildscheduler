# frozen_string_literal: true

class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :event
  attr_accessor :accept_waiver

  validates :guests_registered, :guests_attended, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true

  scope :non_leader, -> { where(leader: false) }
  scope :ordered_by_user_lname, -> { includes(:user).order('users.lname') }

  scope :attended, -> { where(attended: true) }
  scope :leaders, -> { where(leader: true) }
  scope :builders, -> { where.not(leader: true) }
  scope :pre_reminders, -> { where(reminder_sent_at: nil) }

  def form_source
    # this allows for a form field that handles page redirects based on values: "admin", "self", "anon"
  end

  def human_date
    created_at.strftime('%-m/%-d/%Y %H:%M')
  end

  def waiver_accepted?
    user.signed_waiver_on?
  end

  def total_registered
    guests_registered + 1
  end

  def total_attended
    return 0 unless attended?

    guests_attended + 1
  end
end
