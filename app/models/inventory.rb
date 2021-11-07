# frozen_string_literal: true

class Inventory < ApplicationRecord
  has_many :counts, dependent: :destroy
  accepts_nested_attributes_for :counts
  belongs_to :event, optional: true

  scope :latest, -> { order(date: :desc, created_at: :desc).first }
  scope :latest_since, ->(datetime) { where('created_at < ?', datetime).latest }
  scope :latest_completed, -> { where.not(completed_at: nil).order(date: :desc, created_at: :desc).first }
  scope :former, -> { order(date: :desc, created_at: :desc).drop(1) }
  # scope :active, -> { where(deleted_at: nil) }

  validates :date, presence: true

  after_update :transfer_counts, :run_produceable_job

  def count_summary
    summary = "#{item_count} of #{counts.count} items "
    summary +=
      if receiving?
        'received.'
      elsif shipping?
        'shipped.'
      else
        'counted.'
      end

    summary
  end

  def event_based?
    event_id.present?
  end

  def has_items_below_minimum?
    counts.select(&:reorder?).count.positive?
  end

  def item_count
    counts.where.not(user_id: nil).count
  end

  def latest?
    Inventory.latest.id == id
  end

  def name
    "#{date.strftime('%-m/%-d/%y')}: #{type}"
  end

  def name_title
    "#{date.strftime('%m-%d-%y')}: #{type}"
  end

  def primary_counts
    # find the components that represent completed technologies
    @primary_comp_ids = Component.where(completed_tech: true).map(&:id)
    # get the count records of these components
    counts.where(component_id: @primary_comp_ids)
  end

  def technologies
    # inventory#new form field for bypassing technologies
  end

  def type
    if event_id.present?
      'Event Based'
    elsif receiving
      'Items Received'
    elsif shipping
      'Items Shipped'
    elsif manual
      'Manual Inventory'
    else
      'Unknown'
    end
  end

  def type_for_params
    if receiving
      'receiving'
    elsif shipping
      'shipping'
    elsif manual
      'manual'
    elsif event_id.present?
      'event'
    else
      'unknown'
    end
  end

  private

  def run_produceable_job
    ProduceableJob.perform_later unless Delayed::Job.where(queue: 'produceable').any?
  end

  def transfer_counts
    CountTransferJob.perform_later(self) unless Delayed::Job.where(queue: 'count_transfer').any?
  end
end
