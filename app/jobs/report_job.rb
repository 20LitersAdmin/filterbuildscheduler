class ReportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    inventory = Inventory.latest
    ReportMailer.monthly(inventory).deliver_later
  end
end