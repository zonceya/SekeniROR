class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{ENV['DEFAULT_FROM_NAME']} <#{ENV['DEFAULT_FROM_EMAIL']}>" }
  layout 'mailer'
end
