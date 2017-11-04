class User < ApplicationRecord
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
  belongs_to :primary_location, class_name: "Location", primary_key: "id", foreign_key: "primary_location_id", optional: true

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
end
