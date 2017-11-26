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
  #has_and_belongs_to_many :inventories
  has_many :counts
  belongs_to :primary_location, class_name: "Location", primary_key: "id", foreign_key: "primary_location_id", optional: true
  attr_accessor :waiver_accepted

  validates :fname, presence: true
  validates :lname, presence: true
  validates :email, presence: true

  before_save :ensure_authentication_token

  # after_save :notify_email_changed, if: :encrypted_password_changed?

  def admin_or_leader?
    is_admin? || is_leader?
  end

  def does_inventory?
    does_inventory || is_admin
  end

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
    return event.technology.nil? || technologies.exists?(event.technology.id)
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

  def has_no_password
    !encrypted_password.present?
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
