# app/mailers/help_mailer.rb
class HelpMailer < ApplicationMailer
  default from: "SkoolSwap Support <admin@skoolswap.co.za>"

  def support_request(user, subject, description)
    @user = user
    @subject = subject
    @description = description
    
    mail(
      to: 'admin@skoolswap.co.za',
      subject: "Support Request: #{subject}",
      reply_to: user.email
    )
  end

  def auto_reply(user, subject)
    @user = user
    @subject = subject
    
    mail(
      to: user.email,
      subject: "We've received your support request"
    )
  end
end