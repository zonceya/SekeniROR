# app/services/imap_reader.rb
require 'net/imap'

class ImapReader
  BANK_SENDERS = {
    'absa' => 'notifications@absa.co.za',
    'fnb' => 'notifications@fnb.co.za',
    'capitec' => 'notifications@capitecbank.co.za',
    'standard_bank' => 'notifications@standardbank.co.za', 
    'nedbank' => 'notifications@nedbank.co.za',
    'tymebank' => 'notifications@tymebank.co.za'
  }

  def initialize
    @imap = Net::IMAP.new('imap.gmail.com', 993, true)
  end

  def connect(email, app_password)
    @imap.login(email, app_password)
    @imap.select('INBOX')
    Rails.logger.info "✅ Connected to Gmail: #{email}"
  rescue => e
    Rails.logger.error "❌ IMAP connection failed: #{e.message}"
    raise
  end

  def monitor_payments
    # Search for unread payment emails from banks
    query = build_query
    puts "🔍 IMAP Query: #{query}"
    
    message_ids = @imap.search(query)
    
    puts "📧 Found #{message_ids.size} unread payment emails"
    
    message_ids.each do |msg_id|
      process_message(msg_id)
    end
    
    puts "✅ Processed #{message_ids.size} payment emails"
  rescue => e
    puts "❌ Search failed: #{e.message}"
    raise
  end

  private

  def build_query
    # SIMPLER QUERY - Just look for unread emails first
    ['UNSEEN']
    
    # Alternative: Search by sender (commented out for now)
    # bank_senders = BANK_SENDERS.values.map { |email| "FROM #{email}" }
    # ['UNSEEN'] + bank_senders
  end

  def process_message(msg_id)
    puts "📨 Processing message #{msg_id}"
    
    # Get envelope first to check sender
    envelope = @imap.fetch(msg_id, 'ENVELOPE')[0].attr['ENVELOPE']
    from_email = "#{envelope.from[0].mailbox}@#{envelope.from[0].host}"
    
    puts "   From: #{from_email}"
    
    # Check if it's from a bank
    bank = identify_bank(from_email)
    unless bank
      puts "   📧 Not a bank email - skipping"
      mark_as_read(msg_id)
      return
    end
    
    puts "   🏦 Bank detected: #{bank}"
    
    # Get body for payment data
    body = @imap.fetch(msg_id, 'BODY[TEXT]')[0].attr['BODY[TEXT]']
    
    parsed_data = parse_email_data(envelope, body, bank)
    
    if parsed_data && valid_payment_data?(parsed_data)
      puts "   💰 Payment data: #{parsed_data}"
      # PaymentProcessorJob.perform_later(parsed_data)  # Temporarily disabled for testing
      mark_as_read(msg_id)
      puts "   ✅ Processed payment: #{parsed_data[:reference]} - R#{parsed_data[:amount]}"
    else
      puts "   ⚠️ No valid payment data found"
      mark_as_read(msg_id)
    end
  rescue => e
    puts "❌ Failed to process message #{msg_id}: #{e.message}"
    mark_as_flagged(msg_id)
  end

  def parse_email_data(envelope, body, bank)
    puts "   🔍 Parsing email data..."
    
    amount = extract_amount(bank, body)
    reference = extract_reference(bank, body)
    
    puts "   Extracted - Amount: #{amount}, Reference: #{reference}"
    
    {
      bank: bank,
      amount: amount,
      reference: reference,
      timestamp: envelope.date || Time.current
    }
  end

  def identify_bank(from_email)
    BANK_SENDERS.each do |bank, email|
      return bank if from_email.include?(email)
    end
    nil
  end

  def extract_amount(bank, body)
    # Simple amount extraction - look for R amounts
    match = body.match(/R\s*([\d,]+\.\d{2})/i)
    match ? match[1].gsub(',', '').to_f : nil
  end

  def extract_reference(bank, body)
    # Simple reference extraction
    reference = body.match(/Reference:[\s]*([^\s,\r\n]+)/i)&.captures&.first ||
                body.match(/Ref:[\s]*([^\s,\r\n]+)/i)&.captures&.first
    
    clean_reference(reference) if reference
  end

  def clean_reference(reference)
    reference.gsub(/^(ORDER|REF|PAYMENT|REFERENCE|TRANSACTION)[\s\-:]*/i, '')
  end

  def mark_as_read(msg_id)
    @imap.store(msg_id, '+FLAGS', [:Seen])
  end

  def mark_as_flagged(msg_id)
    @imap.store(msg_id, '+FLAGS', [:Seen, :Flagged])
  end

  def valid_payment_data?(parsed_data)
    parsed_data[:amount].to_f > 0 && 
    parsed_data[:reference].present? &&
    parsed_data[:bank].present?
  end

  def disconnect
    @imap.logout
    @imap.disconnect
  rescue
    # Ignore disconnect errors
  end
end