# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'filterbuilds@20liters.org'
  layout 'mailer'
end
