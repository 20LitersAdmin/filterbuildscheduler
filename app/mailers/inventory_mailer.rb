# frozen_string_literal: true

class InventoryMailer < ApplicationMailer
  helper MailerHelper
  default from: "filterbuilds@20liters.org"

  def notify(inventory, user)
    @inventory = inventory
    @user = user
    @recipients = User.notify_inventory.map(&:email)

    @prime_counts = @inventory.primary_counts
    comps = Component.where(id: @prime_counts.map(&:component_id))
    tech_ids = comps.joins(:technologies).map { |c| c.technologies.map(&:id) }.flatten.uniq
    @owners = Technology.status_worthy.where(id: tech_ids).map(&:owner).uniq

    mail(to: @recipients, subject: '[20 Liters] Finalized Inventory Available')
  end
end
