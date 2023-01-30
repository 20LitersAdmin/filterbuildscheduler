# frozen_string_literal: true

class KindfulJob < ApplicationJob
  queue_as :kindful_job

  def perform(_method = '', *_args)
    raise ActiveSupport::Deprecation.warn 'KindfulClient is deprecated, use BloomerangClient instead.'
    # KindfulClient.new.__send__(method, *_args) if method.present?
  end
end
