# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  helper MailerHelper

  default from: "filterbuilds@20liters.org"

  def monthly(inventory)
    @inventory = inventory
    @primary_components = Component.where(completed_tech: true).map { |c| c.id }
    @primary_component_counts = @inventory.counts.where(component_id: @primary_components).sort_by {|c| - c.name }

    @low_counts = @inventory.counts.select{ |count| count.reorder? }
    @total_cost = @low_counts.map { |c| c.item.reorder_total_cost }.sum

    @users_file_name = "20liters_users_from_" + (Date.today.month - 1).to_s + "-" + Date.today.year.to_s + ".csv"
    @users_csv = User.for_monthly_report.to_csv
    
    @recipients = User.all.where(send_inventory_emails: true)

    mail.attachments[@users_file_name] = { mime_type: 'text/csv', content: @users_csv }
    mail( to: @recipients.map{ |u| u.email }, subject: '[20 Liters] Monthly Report' )
    
    puts "-+-+ Monthly report sent to " + @recipients.map{ |r| r.name }.to_s
  end
end
