class ReportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    inventory = Inventory.latest
    puts "-+ Sending monthly report"
    ReportMailer.monthly(inventory).deliver!
    puts "-+ Done sending"
  end
end