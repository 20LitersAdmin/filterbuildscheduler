class Inventory < ApplicationRecord
  acts_as_paranoid

  has_many :counts, dependent: :destroy
  accepts_nested_attributes_for :counts
  belongs_to :event, optional: true

  scope :latest, -> { order(date: :desc).first }
  scope :former, -> { order(date: :desc).drop(1)}

  validates :date, presence: true

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

  def item_count
    counts.where("loose_count > ?", 0).where("unopened_boxes_count > ?", 0).count
  end

  def count_summary
    self.item_count.to_s + " of " + self.counts.count.to_s + " items counted."
  end
end
