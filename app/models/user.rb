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
  has_one :primary_location, class_name: "Location", primary_key: "primary_location_id", foreign_key: "id"
  has_many :qualified_technologies, class_name: "Technology", primary_key: "qualified_technology_ids", foreign_key: "id"
end
