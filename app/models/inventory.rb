class Inventory < ApplicationRecord
  acts_as_paranoid

  has_many :counts, dependent: :destroy
  accepts_nested_attributes_for :counts
  belongs_to :event, optional: true

  scope :latest, -> { order(date: :desc, created_at: :desc).first }
  scope :former, -> { order(date: :desc, created_at: :desc).drop(1) }

  validates :date, presence: true

  def name
    date.strftime("%-m/%-d/%y") + ": " + type
  end

  def name_title
    date.strftime("%m-%d-%y") + " " + type
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

  def type_for_params
    if receiving
      type = "receiving"
    elsif shipping
      type = "shipping"
    elsif manual
      type = "manual"
    elsif event_id.present?
      type = "event"
    else
      type = "unknown"
    end
    type
  end

  def has_items_below_minimum?
    if counts.select{ |count| count.reorder? }.count > 0
      true
    else
      false
    end
  end

  def item_count
    counts.where.not(user_id: nil).count
  end

  def count_summary
    if receiving
      item_count.to_s + " of " + counts.count.to_s + " items received."
    elsif shipping
      item_count.to_s + " of " + counts.count.to_s + " items shipped."
    else
      item_count.to_s + " of " + counts.count.to_s + " items counted."
    end
  end

  def primary_counts
    # find the components that represent completed technologies
    @primary_comp_ids = Component.where(completed_tech: true).map { |c| c.id }
    # get the count records of these components
    counts.where(component_id: @primary_comp_ids)
  end
end
