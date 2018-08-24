# frozen_string_literal: true

class ReportMailerPreview < ActionMailer::Preview
  
  def monthly
    ReportMailer.monthly(Inventory.last)
  end
end
