# frozen_string_literal: true

class InventoryMailer < ApplicationMailer
  helper MailerHelper
  default from: 'filterbuilds@20liters.org'

  def notify(inventory, user)
    @inventory = inventory
    @user = user
    @recipients = User.active.notify_inventory.map(&:email)

    parts = Part.below_minimums
    materials = Material.below_minimums
    @items_below_minimum = [parts, materials].flatten

    mail(to: @recipients, subject: '[20 Liters] Finalized Inventory Available')
  end
end
