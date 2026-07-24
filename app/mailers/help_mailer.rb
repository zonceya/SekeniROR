# app/mailers/help_mailer.rb
class HelpMailer < ApplicationMailer
  default from: "SkoolSwap Support <admin@skoolswap.co.za>"
  layout 'mailer'

  # Email sent to admin when user submits a support request
  def support_request(user, subject, message)
    @user = user
    @subject = subject
    @message = message
    
    mail(
      to: 'admin@skoolswap.co.za',
      subject: "Support Request: #{subject}",
      reply_to: user.email
    )
  end

  # Auto-reply sent to user confirming receipt
  def auto_reply(user, subject)
    @user = user
    @subject = subject
    
    mail(
      to: user.email,
      subject: "We've received your support request: #{subject}"
    )
  end
end