# frozen_string_literal: true

class KindfulJob < ApplicationJob
  queue_as :kindful_job

  def perform(method = '', *_args)
    KindfulClient.new.__send__(method, *_args) if method.present?
  end
end
