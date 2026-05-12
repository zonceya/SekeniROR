# script/test_smtp_direct.rb
require 'net/smtp'

email = "your-email@gmail.com"
otp_code = "123456"

message = <<~EMAIL
From: SkoolSwap <admin@skoolswap.co.za>
To: #{email}
Subject: Test Email

Your OTP code is: #{otp_code}
EMAIL

begin
  Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com',
    ENV['SMTP_USERNAME'],
    ENV['SMTP_PASSWORD'],
    :plain) do |smtp|
    smtp.send_message(message, ENV['SMTP_USERNAME'], email)
  end
  puts "✅ Email sent successfully!"
rescue => e
  puts "❌ Failed: #{e.message}"
end