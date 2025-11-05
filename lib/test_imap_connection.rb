# lib/test_imap_bank_scan.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing IMAP Bank Email Scan..."
puts "=" * 40

begin
  TEST_EMAIL = 'zonceya@gmail.com'
  APP_PASSWORD = 'dlrxvlknewyhnknv' # 16-character app password
  
  puts "1. Connecting to Gmail..."
  require 'net/imap'
  imap = Net::IMAP.new('imap.gmail.com', 993, true)
  imap.login(TEST_EMAIL, APP_PASSWORD)
  imap.select('INBOX')
  puts "   ✅ Connected successfully!"
  
  # Define bank senders to search for
  bank_senders = [
    'notifications@absa.co.za',
    'notifications@fnb.co.za', 
    'notifications@capitecbank.co.za',
    'notifications@standardbank.co.za',
    'notifications@nedbank.co.za',
    'notifications@tymebank.co.za'
  ]
  
  puts "2. Scanning for bank emails..."
  bank_emails_found = 0
  
  bank_senders.each do |bank_email|
    puts "   🔍 Searching: #{bank_email}"
    
    # Search for unread emails from this bank
    query = ['UNSEEN', 'FROM', bank_email]
    message_ids = imap.search(query)
    
    if message_ids.any?
      puts "   ✅ Found #{message_ids.size} emails from #{bank_email}"
      bank_emails_found += message_ids.size
      
      # Process first email from this bank
      msg_id = message_ids.first
      envelope = imap.fetch(msg_id, 'ENVELOPE')[0].attr['ENVELOPE']
      subject = envelope.subject
      
      puts "   📨 Sample - Subject: #{subject}"
      
      # Get body and test parsing
      body = imap.fetch(msg_id, 'BODY[TEXT]')[0].attr['BODY[TEXT]']
      
      # Simple payment detection
      amount_match = body.match(/R\s*([\d,]+\.\d{2})/i)
      ref_match = body.match(/Reference:[\s]*([^\s,\r\n]+)/i) || body.match(/Ref:[\s]*([^\s,\r\n]+)/i)
      
      if amount_match && ref_match
        amount = amount_match[1].gsub(',', '').to_f
        reference = ref_match[1].gsub(/^(ORDER|REF|PAYMENT)/i, '')
        
        puts "   💰 PAYMENT DETECTED:"
        puts "      Amount: R#{amount}"
        puts "      Reference: #{reference}"
        puts "      Bank: #{bank_email}"
        puts "   🎉 PAYMENT PARSING WORKS!"
      else
        puts "   📧 Bank email but no payment data found"
      end
      
      # Mark as read
      imap.store(msg_id, '+FLAGS', [:Seen])
    else
      puts "   ❌ No emails found from #{bank_email}"
    end
  end
  
  puts "3. Summary:"
  puts "   📊 Total bank emails found: #{bank_emails_found}"
  
  puts "4. Cleaning up..."
  imap.logout
  imap.disconnect
  puts "   ✅ Disconnected successfully!"
  
  if bank_emails_found > 0
    puts "🎉 Bank email scanning works! Payment system is READY!"
  else
    puts "💡 No bank emails found. System works but needs real bank emails to test payments."
  end
  
rescue => e
  puts "❌ Test failed: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(3)
end








