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
      format.html { render html: otp_html_content.html_safe }
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
      
      ---
      SkoolSwap - School Shopping Made Easy
    TEXT
  end
  
  def otp_html_content
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
      </head>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
          <tr>
            <td align="center">
              <table width="100%" max-width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px;">
                <tr>
                  <td style="padding: 40px 30px;">
                    <h2 style="color: #333; margin: 0 0 20px 0; text-align: center;">🔐 Verify Your Login</h2>
                    
                    <p style="color: #666; margin: 0 0 15px 0; font-size: 16px;">Hello,</p>
                    
                    <p style="color: #666; margin: 0 0 25px 0; font-size: 16px;">Use the code below to complete your sign in to <strong style="color: #2c3e50;">SkoolSwap</strong>:</p>
                    
                    <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; text-align: center; margin: 25px 0;">
                      <span style="font-size: 42px; font-weight: bold; letter-spacing: 8px; color: #2c3e50; font-family: monospace;">#{@otp_code}</span>
                    </div>
                    
                    <p style="color: #666; font-size: 14px; margin: 0 0 5px 0;">This code will expire in <strong>#{@expiry_minutes} minutes</strong>.</p>
                    
                    <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 30px 0 20px 0;">
                    
                    <p style="color: #999; font-size: 12px; margin: 0; text-align: center;">
                      If you didn't request this code, please ignore this email.<br>
                      © 2025 SkoolSwap. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
      </html>
    HTML
  end
end