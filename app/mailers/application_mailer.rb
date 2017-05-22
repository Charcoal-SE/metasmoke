# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'metasmoke@erwaysoftware.com'
  layout 'mailer'
end
