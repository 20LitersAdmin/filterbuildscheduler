# frozen_string_literal: true

class InventoryMailer < ApplicationMailer
  helper MailerHelper
  default from: "filterbuilds@20liters.org"

  def notify(inventory, user)
    @inventory = inventory
    @user = user
    @recipients = User.where(send_inventory_emails: true).map { |u| u.email }

    if @inventory.has_items_below_minimum?
      @low_items = @inventory.counts.select{ |count| count.reorder? }
    end

    mail(to: @recipients, subject: '[20 Liters] Finalized Inventory Available')
  end
end
