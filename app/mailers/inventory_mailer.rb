class InventoryMailer < ApplicationMailer
  helper MailerHelper
  default from: "filterbuilds@20liters.org"

  def notify(inventory, user)
    @inventory = inventory
    @user = user
    @recipients = User.where(send_inventory_emails: true).map { |u| u.email }
    mail(to: @recipients, subject: '[20 Liters] Finalized Inventory Available')
  end
end
