# frozen_string_literal: true

class BloomerangJob < ApplicationJob
  queue_as :bloomerang_job

  def perform(method = '', *args)
    BloomerangClient.new.__send__(method, *args) if method.present?
  end
end
