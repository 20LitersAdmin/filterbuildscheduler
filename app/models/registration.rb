class Registration < ApplicationRecord
  acts_as_paranoid

  belongs_to :user
  belongs_to :event
  scope :registered_as_leader, -> {where(leader: true)}
  scope :non_leader, -> {where(leader: false)}
  scope :ordered_by_user_lname, -> { includes(:user).order('users.lname')}
  # delegate :signed_waiver_on, to: :user, prefix: :false, allow_nil: false
  # attr_accessor :waiver_accepted?

  validates :guests_registered, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true
  validate :under_max_registrations?
  validate :under_max_leaders?

  def under_max_registrations?
    return if leader?

    if self.guests_registered == nil
      self.guests_registered = 0
    end

    # Diff in count of attendees - if it's a new record, it's the total guest count plus the registrant.
    # If it's an update, it's just the difference in guest count. 
    # Special case if the user registered as a leader then de-registered.
    attendees_diff = new_record? ? guests_registered + 1 : guests_registered - guests_registered_was - (leader_was ? 1 : 0)

    # overflow represents how many attendees we would be over max if this registration succeeded
    overflow = event.total_registered + attendees_diff - event.max_registrations

    if overflow > 0
      #errors.add(:email, "maximum registrations exceeded by #{overflow} for event")
      self.errors.add(:guests_registered, "maximum registrations exceeded by #{overflow} for event")
    end
  end

  def under_max_leaders?
    return if !leader?

    leader_added = leader? && !leader_was
    leader_removed = !leader? && leader_was
    leader_diff = leader_added ? 1 : leader_removed ? -1 : 0

    if event.leaders_registered.count + leader_diff > event.max_leaders
      errors.add(:leader, 'maximum leaders exceeded for event')
    end
  end

  def form_source
    # this allows for a form field that handles page redirects based on values: "admin", "self", "anon"
  end

  def human_date
    created_at.strftime("%-m/%-d/%Y %H:%M")
  end

  def waiver_accepted?
    user.signed_waiver_on?
  end

end
