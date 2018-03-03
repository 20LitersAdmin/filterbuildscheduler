class User < ApplicationRecord
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  scope :leaders, -> { where(is_leader: true)}
  scope :admins, -> { where(is_admin: true) }
  scope :builders, -> { where.not(is_admin: true).where.not(is_leader: true).where.not(does_inventory: true)}
  scope :for_monthly_report, -> { builders.where(email_opt_out: false).where('created_at >= ?', Date.today.beginning_of_month) }
  
  has_many :registrations
  has_many :events, through: :registrations
  has_and_belongs_to_many :technologies
  has_many :counts
  belongs_to :primary_location, class_name: "Location", primary_key: "id", foreign_key: "primary_location_id", optional: true

  validates :fname, :lname, :email, presence: true

  before_save :ensure_authentication_token, :check_phone_format

  after_save :update_kindful, if: Proc.new { |user| user.saved_change_to_fname? || user.saved_change_to_lname? || user.saved_change_to_email? || user.saved_change_to_email_opt_out? }

  def admin_or_leader?
    is_admin? || is_leader?
  end

  def does_inventory?
    does_inventory || is_admin || send_inventory_emails
  end

  def name
    "#{fname} #{lname}"
  end

  def password_required?
    false
  end

  def can_lead_event?(event)
    return false unless admin_or_leader?
    return event.technology.nil? || technologies.exists?(event.technology.id)
  end

  def registered?(event)
    Registration.where(user: self, event: event).present?
  end

  def leading?(event)
    Registration.where(user: self, event: event, leader: true).present?
  end

  def available_events
    if is_admin?
      Event.all
    elsif is_leader?
      # finds future events OR events the leader registered for
      Event.distinct.joins('LEFT JOIN registrations ON registrations.event_id = events.id')
         .where('start_time >= ? OR registrations.user_id = ?', Time.now, id)
    else
      # finds public events OR events the user has registered for
      Event.distinct.joins('LEFT JOIN registrations ON registrations.event_id = events.id')
         .where('is_private = false OR registrations.user_id = ?', id)
    end
  end

  def has_no_password
    !encrypted_password.present?
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def check_phone_format
    if phone.present? && phone.match('^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$').nil?
      # Remove any non-numbers, and any symbols that aren't part of [(,),-,.,+]
      phone.gsub!(/[^\d,(,),+,\s,.,-]/,'')
    end
  end

  def self.to_csv
    attributes = %w[fname lname email]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |u|
        csv << u.attributes.values_at(*attributes)
      end
    end
  end

  def custom_path
    # this allows for a form field that handles page redirects based on values: "admin", "self"
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end

  def update_kindful
    KindfulClient.new.import_user(self)
  end
end
