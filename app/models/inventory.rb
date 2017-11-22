class Inventory < ApplicationRecord
  acts_as_paranoid

  has_many :counts, dependent: :destroy
  accepts_nested_attributes_for :counts
  belongs_to :event, optional: true

  #has_and_belongs_to_many :technologies
  #has_and_belongs_to_many :users

  scope :latest, -> { order(date: :desc).first }
  scope :former, -> { order(date: :desc).drop(1)}

  amoeba do
    include_association :counts
  end

  def name
    date.strftime("%-m/%-d/%y") + ": " + type
  end

  def type
    if event_id.present?
      type = "Event Based"
    elsif receiving
      type = "Items Received"
    elsif shipping
      type = "Items Shipped"
    elsif manual
      type = "Manual Inventory"
    else
      type = "Unknown"
    end
    type
  end
end
