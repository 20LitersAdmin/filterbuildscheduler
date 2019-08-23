# frozen_string_literal: true

class InventoryMailerPreview < ActionMailer::Preview

  def notify
    InventoryMailer.notify(Inventory.latest, User.first)
  end
end
