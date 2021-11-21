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

  after_update :run_count_transfer_job, :run_produceable_job

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

  def name
    "#{date.strftime('%-m/%-d/%y')}: #{type}"
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
    else # manual
      'Manual'
    end
  end

  def type_for_params
    if receiving
      'receiving'
    elsif shipping
      'shipping'
    elsif event_id.present?
      'event'
    else # manual
      'manual'
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

  private

  def item_count
    counts.where.not(user_id: nil).count
  end

  def run_produceable_job
    return unless completed_at.present?

    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'produceable', locked_at: nil).delete_all

    ProduceableJob.perform_later
  end

  def run_count_transfer_job
    return unless completed_at.present?

    # Delete any jobs that exist, but haven't started, in favor of this new job
    Delayed::Job.where(queue: 'count_transfer', locked_at: nil).delete_all

    CountTransferJob.perform_later(self)
  end
end
