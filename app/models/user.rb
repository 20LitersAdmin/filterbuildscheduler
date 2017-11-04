class User < ApplicationRecord
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  scope :leaders, -> {active.where(is_leader: true)}
  scope :builders, -> {active}
  scope :admin, -> {where(is_admin: true)}
  has_many :registrations
  has_many :events, through: :registrations
  has_and_belongs_to_many :technologies
  belongs_to :primary_location, class_name: "Location", primary_key: "id", foreign_key: "primary_location_id", optional: true
  attr_accessor :waiver_accepted

  def name
    "#{fname} #{lname}"
  end

  def waiver_accepted
    !signed_waiver_on.nil?
  end

  def password_required?
    false
  end

  def qualified_technologies
    if is_leader?
      Technology.find_by(id: qualified_technology_id)
    else
      Technology.none
    end
  end

  def can_lead_event?(event)
    return false unless is_leader
    return event.technology.nil? || qualified_technologies.exists?(event.technology)
  end

  def registered?(event)
    Registration.where(user: self, event: event).present?
  end

  def available_events
    Event.joins('LEFT OUTER JOIN registrations ON registrations.event_id = events.id')
         .where('is_private = ? OR registrations.user_id = ?', false, id)
  end
end
