# frozen_string_literal: true

class CountsChannel < ApplicationCable::Channel
  def subscribed
    inventory = Inventory.find(params[:inventory_id])
    stream_for inventory
  end
end
