# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: '20 Liters <filterbuilds@20liters.org>', reply_to: 'filterbuilds@20liters.org'
  layout 'mailer'
end
