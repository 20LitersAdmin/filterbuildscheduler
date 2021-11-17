# frozen_string_literal: true

class Inventory < ApplicationRecord
  has_many :counts, dependent: :destroy
  accepts_nested_attributes_for :counts
  belongs_to :event, optional: true

  scope :latest, -> { order(date: :desc, created_at: :desc).first }
  scope :latest_since, ->(datetime) { where('created_at < ?', datetime).latest }
  scope :latest_completed, -> { where.not(completed_at: nil).order(date: :desc, created_at: :desc).first }
  scope :former, -> { order(date: :desc, created_at: :desc).drop(1) }

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

  def technologies
    # inventory#new form field for bypassing technologies
  end

  def type
    if event_id.present?
      'Event Based'
    elsif receiving
      'Receiving'
    elsif shipping
      'Shipping'
    elsif manual
      'Manual'
    else
      'Unknown'
    end
  end

  def verb_past_tense
    if event_id.present?
      'adjusted after an event'
    elsif receiving
      'received'
    elsif shipping
      'shipped'
    else
      'counted'
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
    return unless completed_at.present?

    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'produceable', locked_at: nil).delete_all

    ProduceableJob.perform_later
  end

  def transfer_counts
    return unless completed_at.present?

    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'count_transfer', locked_at: nil).delete_all

    CountTransferJob.perform_later(self)
  end
end
