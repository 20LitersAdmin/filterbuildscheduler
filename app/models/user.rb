# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :registrations, dependent: :destroy
  has_many :events, through: :registrations
  has_and_belongs_to_many :technologies
  has_many :counts
  belongs_to :primary_location, class_name: 'Location', primary_key: 'id', foreign_key: 'primary_location_id', optional: true

  scope :leaders, -> { where(is_leader: true) }
  scope :admins, -> { where(is_admin: true) }
  scope :builders, -> { where(is_admin: false, is_leader: false, does_inventory: false, send_notification_emails: false, send_inventory_emails: false) }
  scope :for_monthly_report, -> { builders.where(email_opt_out: false).where('created_at >= ?', Date.today.beginning_of_month) }

  validates :fname, :lname, :email, presence: true

  validates_confirmation_of :password

  before_save :ensure_authentication_token, :check_phone_format

  # https://github.com/plataformatec/devise/issues/5033
  before_save do |user|
    if user.will_save_change_to_encrypted_password?
      user.restore_encrypted_password! unless user.encrypted_password.present?
    end
  end

  after_save :update_kindful, if: ->(user) { user.saved_change_to_fname? || user.saved_change_to_lname? || user.saved_change_to_email? || user.saved_change_to_email_opt_out? || user.saved_change_to_phone? }

  scope :active, -> { where(deleted_at: nil) }

  def admin_or_leader?
    is_admin? || is_leader?
  end

  def can_do_inventory?
    does_inventory? || is_admin? || send_inventory_emails?
  end

  def name
    "#{fname} #{lname}"
  end

  def password_required?
    false
  end

  def can_lead_event?(event)
    return false unless admin_or_leader?

    event.technology.nil? || technologies.exists?(event.technology.id)
  end

  def registered?(event)
    Registration.where(user: self, event: event).present?
  end

  def leading?(event)
    Registration.where(user: self, event: event, leader: true).present?
  end

  def available_events
    if admin_or_leader?
      Event.all
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
    self.authentication_token = generate_authentication_token if authentication_token.blank?
  end

  def check_phone_format
    # Remove any non-numbers, and any symbols that aren't part of [(,),-,.,+]
    phone.gsub!(/[^\d,(,),+,\s,.,-]/,'') if phone.present? && phone.match('^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$').nil?
  end

  def latest_event
    if registrations.count.positive?
      registrations.includes(:event).order('events.start_time DESC').first.event.full_title
    else
      'No Event'
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
    # this allows for a form field that handles page redirects based on values: 'admin', 'self'
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
