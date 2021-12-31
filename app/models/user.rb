# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  # SCHEMA NOTES: Roles:
  # is_admin
  # is_leader
  # does_inventory # (inventoryist)
  # is_scheduler
  # is_data_manager
  # is_oauth_admin
  # none of the above == builder
  # not signed in == anon user

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

  # maps to User(leader_type: integer)
  # getter: user.trainee?
  # setter: user.trainee!
  enum leader_type: %i[trainee helper primary]

  validates :fname, :lname, :email, presence: true
  validates_confirmation_of :password

  # rails_admin scope "active" sounds better than "kept"
  scope :active, -> { kept }

  scope :admins,                -> { kept.where(is_admin: true) }
  scope :builders,              -> { kept.where(is_admin: false, is_leader: false, does_inventory: false, send_notification_emails: false, send_inventory_emails: false) }
  scope :data_managers,         -> { kept.where(is_data_manager: true) }
  scope :inventoryists,         -> { kept.where(does_inventory: true) }
  scope :leaders,               -> { kept.where(is_leader: true) }
  scope :notify,                -> { kept.where(send_notification_emails: true) }
  scope :notify_inventory,      -> { kept.where(send_inventory_emails: true) }
  scope :non_builders,          -> { kept.where('is_admin = TRUE OR is_leader = TRUE OR does_inventory = TRUE OR is_scheduler = TRUE OR is_data_manager = TRUE') }
  scope :schedulers,            -> { kept.where(is_scheduler: true) }
  scope :with_registrations,    -> { joins(:registrations).uniq }
  scope :without_registrations, -> { left_outer_joins(:registrations).where(registrations: { id: nil }) }

  before_save :ensure_authentication_token, :check_phone_format

  # https://github.com/plataformatec/devise/issues/5033
  before_save do |user|
    user.restore_encrypted_password! if user.will_save_change_to_encrypted_password? && user.encrypted_password.blank?
  end

  after_save :update_kindful, if: ->(user) { user.saved_change_to_fname? || user.saved_change_to_lname? || user.saved_change_to_email? || user.saved_change_to_email_opt_out? || user.saved_change_to_phone? }

  def admin_or_leader?
    is_admin? ||
      is_leader? ||
      does_inventory? ||
      is_scheduler? ||
      is_data_manager?
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
      Event.kept
    else
      # finds public events OR events the user has registered for
      Event.kept.distinct.joins('LEFT JOIN registrations ON registrations.event_id = events.id')
           .where('is_private = false OR registrations.user_id = ?', id)
    end
  end

  def can_do_inventory?
    is_admin? ||
      does_inventory? ||
      is_data_manager?
  end

  def can_view_inventory?
    can_do_inventory? ||
      send_inventory_emails?
  end

  def can_edit_events?
    is_admin? ||
      is_leader? ||
      is_scheduler? ||
      is_data_manager?
  end

  def can_manage_data?
    is_admin? ||
      is_data_manager?
  end

  def can_manage_leaders?
    is_admin? || is_scheduler?
  end

  def can_manage_users?
    is_admin? ||
      is_scheduler? ||
      is_data_manager?
  end

  def can_lead_event?(event)
    return false unless admin_or_leader?

    event.technology.nil? || technologies.exists?(event.technology.id)
  end

  def custom_path
    # this allows for a form field that handles page redirects based on values: 'admin', 'self'
  end

  def email_domain
    # this can be simple because it is only trying to match against Constants::Email::INTERNAL_DOMAINS
    # see OauthUserPolicy#in?
    email[/@\w+/i]
  end

  def email_opt_in
    # KindfulClient wants email_opt_in, not email_opt_out
    !email_opt_out?
  end

  def events_attended
    applicable_event_ids = registrations.past.kept.attended.map(&:event_id)

    Event.where(id: applicable_event_ids)
  end

  def events_led
    return Event.none unless is_leader?

    applicable_event_ids = registrations.past.kept.attended.leaders.map(&:event_id)

    Event.where(id: applicable_event_ids)
  end

  def events_list
    str = '<ul>'
    events.complete.limit(5).each do |event|
      event_link = ActionController::Base.helpers.link_to event.full_title_w_year, Rails.application.routes.url_helpers.event_path(event.id)
      str += "<li>#{event_link}</li>"
    end
    str += '</ul>'

    str.html_safe
  end

  def events_skipped
    applicable_event_ids = registrations.past.kept.where(attended: false).map(&:event_id)

    Event.where(id: applicable_event_ids)
  end

  def has_no_password
    !encrypted_password.present?
  end

  def has_password
    encrypted_password.present?
  end

  def leading?(event)
    return false unless is_leader?

    registrations.kept.leaders.where(event: event).present?
  end

  def name
    "#{fname} #{lname}"
  end

  def password_required?
    # Devise: make password optional
    false
  end

  def registered?(event)
    Registration.kept.where(user: self, event: event).present?
  end

  def role_ary
    # rails_admin users#index and #show
    ary = []
    ary << 'Admin' if is_admin
    ary << 'Leader' if is_leader
    ary << 'Inventoryist' if does_inventory
    ary << 'Scheduler' if is_scheduler
    ary << 'Data Manager' if is_data_manager
    ary << 'Oauth Admin' if is_oauth_admin

    ary << 'Builder' if ary.blank?

    ary
  end

  def role
    # rails_admin users#index
    role_ary.to_sentence
  end

  def role_html
    # rails_admin users#show
    block = '<ul>'
    role_ary.each do |r|
      block += "<li>#{r}</li>"
    end

    block += '</ul>'
    block.html_safe
  end

  def send_reset_password_email
    # RailsAdmin custom form field with custom partial
    # custom partial links to UsersController#admin_password_reset
    # which fires Devise#send_reset_password_instructions
  end

  def total_volunteer_hours
    registrations.kept
                 .attended
                 .includes(:event)
                 .map { |r| r.event.length }
                 .sum
  end

  def total_leader_hours
    return 0 unless is_leader?

    registrations.kept
                 .attended
                 .leaders
                 .includes(:event)
                 .map { |r| r.event.length }
                 .sum
  end

  def total_guests
    registrations.attended.map(&:guests_attended).sum
  end

  def techs_qualified
    return unless is_leader? && technologies.any?

    ary = []
    technologies.list_worthy.order(:name).pluck(:name, :owner).each do |tech|
      ary << "#{tech[0]} (#{tech[1]})"
    end

    ary
  end

  def techs_qualified_html
    return unless is_leader? && technologies.any?

    str = '<ul>'
    techs_qualified.each do |tech|
      str += "<li>#{tech}</li>"
    end
    str += '</ul>'

    str.html_safe
  end

  private

  def ensure_authentication_token
    self.authentication_token = generate_authentication_token if authentication_token.blank?
  end

  def check_phone_format
    # Remove any non-numbers, and any symbols that aren't part of [(,),-,.,+]
    phone.gsub!(/[^\d,(,),+,\s,.,-]/, '') if phone.present? && phone.match('^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$').nil?
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      # return token unless it's already been assigned to some user
      break token unless User.where(authentication_token: token).first
    end
  end

  def update_kindful
    KindfulClient.new.import_user(self)
  end
end
