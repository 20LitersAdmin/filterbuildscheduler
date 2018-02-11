class ReportMailerPreview < ActionMailer::Preview
  
  def monthly
    ReportMailer.monthly(Inventory.last)
  end
end