# frozen_string_literal: true

class ReportJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    puts '-+ Cleaning up the ReportJob list'
    Delayed::Job.all.each do |job|
      job.destroy if job.name.include?('ReportJob')
    end

    inventory = Inventory.latest_completed
    if inventory.present? && inventory.report_sent_at.nil?
      puts '-+ Sending monthly report'
      ReportMailer.monthly(inventory).deliver_now!
      inventory.update(report_sent_at: Time.zone.now)
    else
      puts '-+ No report to send'
    end
    puts '-+ Done sending'
  end
end
