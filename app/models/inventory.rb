class Inventory < ApplicationRecord
  acts_as_paranoid

  has_many :counts
  accepts_nested_attributes_for :counts

  #has_and_belongs_to_many :technologies
  #has_and_belongs_to_many :users

  scope :latest, -> { order(date: :desc).first }
  scope :former, -> { order(date: :desc).drop(1)}

  amoeba do
    include_association :counts
  end

  def name
    "#" + id.to_s + ": " + date.strftime("%-m/%-d/%y") + ": " + type
  end

  def type
    if event_id.present?
      type = "Event Based"
    end
    if receiving
      type = "Items Received"
    end
    if shipping
      type = "Items Shipped"
    end
    if !event_id.present? && !receiving && !shipping
      type = "Manual Inventory"
    end
    type
  end
end
