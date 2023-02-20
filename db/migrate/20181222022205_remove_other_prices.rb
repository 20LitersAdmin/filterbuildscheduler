# frozen_string_literal: true

class RemoveOtherPrices < ActiveRecord::Migration[5.2]
  def change
    remove_column :parts, :shipping_cost_cents
    remove_column :parts, :shipping_cost_currency
    remove_column :parts, :additional_cost_cents
    remove_column :parts, :additional_cost_currency
    remove_column :parts, :wire_transfer_cost_cents
    remove_column :parts, :wire_transfer_cost_currency

    remove_column :materials, :shipping_cost_cents
    remove_column :materials, :shipping_cost_currency
    remove_column :materials, :additional_cost_cents
    remove_column :materials, :additional_cost_currency
    remove_column :materials, :wire_transfer_cost_cents
    remove_column :materials, :wire_transfer_cost_currency
  end
end
