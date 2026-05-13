# app/mailers/otp_mailer.rb
class OtpMailer < ApplicationMailer
  def send_login_otp(email, otp_code)
    @otp_code = otp_code
    @expiry_minutes = 15
    
    mail(
      to: email,
      subject: "🔐 Your SkoolSwap Login Code - #{otp_code}"
    ) do |format|
      format.text { render plain: otp_text_content }
      format.html { render html: otp_html_content }
    end
  end
  
  private
  
  def otp_text_content
    <<~TEXT
      Welcome to SkoolSwap!
      
      Your login verification code is: #{@otp_code}
      
      This code will expire in #{@expiry_minutes} minutes.
      
      If you didn't request this code, please ignore this email.
      
      Thanks,
      The SkoolSwap Team
    TEXT
  end
  
  def otp_html_content
    <<~HTML
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #333; text-align: center;">🔐 Verify Your Login</h2>
        
        <p style="color: #666; font-size: 16px;">Hello,</p>
        
        <p style="color: #666; font-size: 16px;">Use the code below to complete your sign in to <strong>SkoolSwap</strong>:</p>
        
        <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
          <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #2c3e50;">#{@otp_code}</span>
        </div>
        
        <p style="color: #666; font-size: 14px;">This code will expire in <strong>#{@expiry_minutes} minutes</strong>.</p>
        
        <p style="color: #999; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
          If you didn't request this code, please ignore this email.<br>
          © 2025 SkoolSwap. All rights reserved.
        </p>
      </div>
    HTML
  end
end