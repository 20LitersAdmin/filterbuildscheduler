# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  has_many :registrations, dependent: :destroy
  has_many :events, through: :registrations
  has_and_belongs_to_many :technologies
  has_many :counts
  belongs_to :primary_location, class_name: 'Location', primary_key: 'id', foreign_key: 'primary_location_id', optional: true

  validates :fname, :lname, :email, presence: true
  validates_confirmation_of :password
  before_save :ensure_authentication_token, :check_phone_format

  # TODO: Second deployment
  # scope :kept, -> { all }
  # scope :discarded, -> { none }

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :leaders,               -> { kept.where(is_leader: true) }
  scope :inventoryists,         -> { kept.where(does_inventory: true) }
  scope :admins,                -> { kept.where(is_admin: true) }
  scope :notify,                -> { where(send_notification_emails: true) }
  scope :notify_inventory,      -> { where(send_inventory_emails: true) }
  scope :builders,              -> { kept.where(is_admin: false, is_leader: false, does_inventory: false, send_notification_emails: false, send_inventory_emails: false) }
  scope :non_builders,          -> { where(is_admin: true).or(where(is_leader: true)).or(where(does_inventory: true)).or(where(send_notification_emails: true)).or(where(send_inventory_emails: true)) }
  scope :for_monthly_report,    -> { builders.where(email_opt_out: false).where('created_at >= ?', Date.today.beginning_of_month) }
  scope :with_registrations,    -> { joins(:registrations).uniq }
  scope :without_registrations, -> { left_outer_joins(:registrations).where(registrations: { id: nil }) }

  # https://github.com/plataformatec/devise/issues/5033
  before_save do |user|
    user.restore_encrypted_password! if user.will_save_change_to_encrypted_password? && user.encrypted_password.blank?
  end

  after_save :update_kindful, if: ->(user) { user.saved_change_to_fname? || user.saved_change_to_lname? || user.saved_change_to_email? || user.saved_change_to_email_opt_out? || user.saved_change_to_phone? }

  def admin_or_leader?
    is_admin? || is_leader?
  end

  def availability
    # [['All hours', 0], ['Business hours', 1], ['After hours', 2]]
    return unless is_leader?

    return 'All hours' if available_business_hours? && available_after_hours?

    return 'Business hours' if available_business_hours? && !available_after_hours?

    return 'After hours' if available_after_hours? && !available_business_hours

    'Unknown'
  end

  def availability_code
    # [['All hours', 0], ['Business hours', 1], ['After-hours', 2]]
    return unless is_leader?

    return 0 if available_business_hours? && available_after_hours?

    return 1 if available_business_hours? && !available_after_hours?

    return 2 if available_after_hours? && !available_business_hours

    nil
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

  def can_do_inventory?
    does_inventory? || admin_or_leader? || send_inventory_emails?
  end

  def can_lead_event?(event)
    return false unless admin_or_leader?

    event.technology.nil? || technologies.exists?(event.technology.id)
  end

  def custom_path
    # this allows for a form field that handles page redirects based on values: 'admin', 'self'
  end

  def email_opt_in
    # KindfulClient wants email_opt_in, not email_opt_out
    !email_opt_out?
  end

  def events_attended
    applicable_event_ids = registrations.attended.joins(:event).where('events.discarded_at IS NULL').map(&:event_id)

    Event.where(id: applicable_event_ids)
  end

  def events_led
    applicable_event_ids = registrations.attended.leaders.joins(:event).where('events.discarded_at IS NULL').map(&:event_id)

    Event.where(id: applicable_event_ids).any? ? Event.where(id: applicable_event_ids) : nil
  end

  def events_skipped
    applicable_event_ids = registrations.where(attended: false).joins(:event).where('events.discarded_at IS NULL').map(&:event_id)

    Event.where(id: applicable_event_ids)
  end

  def events_led_between(start_date: nil, end_date: nil)
    return unless is_leader?

    applicable_event_ids = registrations.attended.joins(:event).map(&:event_id)

    if start_date.present? && end_date.present?
      Event.where(end_time: start_date..end_date).where(id: applicable_event_ids).order(start_time: :asc)
    elsif start_date.present?
      Event.where('start_time >= ?', start_date).where(id: applicable_event_ids).order(start_time: :asc)
    elsif end_date.present?
      Event.where('end_time <= ?', end_date).where(id: applicable_event_ids).order(start_time: :asc)
    else
      Event.where(id: applicable_event_ids).order(start_time: :asc)
    end
  end

  def has_no_password
    !encrypted_password.present?
  end

  def has_password
    encrypted_password.present?
  end

  def latest_event
    if registrations.count.positive?
      registrations.includes(:event)
                   .order('events.start_time DESC')
                   .first
                   .event
                   .name
    else
      'No Event'
    end
  end

  def leading?(event)
    Registration.where(user: self, event: event, leader: true).present?
  end

  def name
    "#{fname} #{lname}"
  end

  def password_required?
    false
  end

  def registered?(event)
    Registration.where(user: self, event: event).present?
  end

  def role
    if is_admin?
      'Admin'
    elsif is_leader?
      'Leader'
    elsif does_inventory?
      'Inventory'
    else
      'Builder'
    end
  end

  def role_leadership_html
    ary = []
    ary << 'Admin' if is_admin?
    ary << 'Leader' if is_leader?
    ary << 'Inventoryist' if does_inventory?
    ary << 'Notified of events' if send_notification_emails?
    ary << 'Notified of inventories' if send_inventory_emails?

    return unless ary.any?

    str = '<ul>'
    ary.each do |role|
      str += "<li>#{role}</li>"
    end
    str += '</ul>'

    str.html_safe
  end

  def send_reset_password_email
    # RailsAdmin custom form field with custom partial
    # custom partial links to UsersController#admin_password_reset
    # which fires Devise#send_reset_password_instructions
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

  def total_volunteer_hours
    registrations.attended
                 .includes(:event)
                 .map { |r| r.event.length }
                 .sum
  end

  def total_leader_hours
    return unless is_leader?

    registrations.attended
                 .leaders
                 .includes(:event)
                 .map { |r| r.event.length }
                 .sum
  end

  def total_guests
    registrations.attended.map(&:guests_attended).sum
  end

  def techs_qualified
    return unless is_leader?

    ary = []
    technologies.list_worthy.order(:name).pluck(:name, :owner).each do |tech|
      ary << "#{tech[0]} (#{tech[1]})"
    end

    ary
  end

  def techs_qualified_html
    return unless is_leader?

    str = '<ul>'
    techs_qualified.each do |tech|
      str += "<li>#{tech}</li>"
    end
    str += '</ul>'

    str.html_safe
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

  def ensure_authentication_token
    self.authentication_token = generate_authentication_token if authentication_token.blank?
  end

  def check_phone_format
    # Remove any non-numbers, and any symbols that aren't part of [(,),-,.,+]
    phone.gsub!(/[^\d,(,),+,\s,.,-]/, '') if phone.present? && phone.match('^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$').nil?
  end
end
