class InventoryMailerPreview < ActionMailer::Preview

  def notify
    InventoryMailer.notify(Inventory.last, User.first)
  end
end
