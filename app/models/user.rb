class User < ApplicationRecord
  acts_as_token_authenticatable
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  scope :archived, -> {where(is_archived: true)}
  scope :active, -> {where(is_archived: false)}
  scope :leaders, -> {active.where(is_leader: true)}
  scope :builders, -> {active}
  scope :admin, -> {where(is_admin: true)}
  has_many :registrations
  has_many :events, through: :registrations
  has_and_belongs_to_many :technologies
  belongs_to :primary_location, class_name: "Location", primary_key: "id", foreign_key: "primary_location_id", optional: true
  attr_accessor :waiver_accepted

  validates :fname, presence: true
  validates :lname, presence: true
  validates :email, presence: true

  def name
    "#{fname} #{lname}"
  end

  def waiver_accepted
    !signed_waiver_on.nil?
  end

  def password_required?
    false
  end

  def can_lead_event?(event)
    return false unless is_leader
    return event.technology.nil? || qualified_technologies.exists?(event.technology)
  end

  def registered?(event)
    Registration.where(user: self, event: event).present?
  end

  def leading?(event)
    Registration.where(user: self, event: event, leader: true).present?
  end

  def available_events
    Event.distinct.joins('LEFT JOIN registrations ON registrations.event_id = events.id')
         .where('is_private = false OR registrations.user_id = ?', id)
  end
end
