# app/services/gmail_reader.rb
module Gmail
class GmailReader
  BANK_SENDERS = {
    'absa' => 'notifications@absa.co.za',
    'fnb' => 'notifications@fnb.co.za',
    'capitec' => 'notifications@capitecbank.co.za',
    'standard_bank' => 'notifications@standardbank.co.za',
    'nedbank' => 'notifications@nedbank.co.za',
    'tymebank' => 'notifications@tymebank.co.za'
  }
  def self.parse(raw_email)
      body = extract_body(raw_email)
      bank = identify_bank(raw_email)
      
      return unless bank

      amount = extract_amount(bank, body)
      reference = extract_reference(bank, body)
      
      # Only return data if it looks like a valid payment
      if amount.to_f > 0 && reference.present?
        {
          bank: bank,
          amount: amount,
          reference: clean_reference(reference),
          timestamp: extract_timestamp(raw_email),
          sender_email: extract_sender(raw_email),
          subject: extract_subject(raw_email),
          email_date: extract_date(raw_email),
          raw_body_preview: body[0..200] # First 200 chars for debugging
        }
      end
    end
  class << self
    # Main method to monitor all bank payments
    def monitor_bank_payments
      service = initialize_gmail_service
      query = build_payment_query
      
      messages = service.list_user_messages('me', q: query).messages || []
      Rails.logger.info "Found #{messages.size} unread payment emails"
      
      messages.each do |msg|
        process_payment_message(service, msg)
      end
      
      Rails.logger.info "Processed #{messages.size} payment emails"
    end

    # Alternative: Fetch all bank notifications (broader scope)
    def fetch_bank_notifications
      service = initialize_gmail_service
      query = build_bank_query
      
      messages = service.list_user_messages('me', q: query).messages || []
      Rails.logger.info "Found #{messages.size} bank notification emails"
      
      messages.each do |msg|
        process_message(service, msg)
      end
    end

    private

    def self.extract_subject(raw_email)
      subject_header = raw_email[:payload][:headers].find { |h| h[:name] == 'Subject' }
      subject_header[:value] if subject_header
    end

    def self.extract_date(raw_email)
      date_header = raw_email[:payload][:headers].find { |h| h[:name] == 'Date' }
      date_header[:value] if date_header
    end

    def self.extract_sender(raw_email)
      from_header = raw_email[:payload][:headers].find { |h| h[:name] == 'From' }
      from_header[:value] if from_header
    end
    def initialize_gmail_service
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(Rails.application.credentials.google_service_account.to_json),
        scope: ['https://www.googleapis.com/auth/gmail.readonly']
      )
      
      service = Google::Apis::GmailV1::GmailService.new
      service.authorization = credentials
      service
    end

    # Specific query for payment-related emails
    def build_payment_query
      bank_emails = BANK_SENDERS.values
      bank_query = bank_emails.map { |email| "from:#{email}" }.join(' OR ')
      
      "#{bank_query} AND (subject:payment OR subject:deposit OR subject:transfer OR subject:credit OR subject:eft) AND is:unread"
    end

    # Broader query for all bank notifications
    def build_bank_query
      BANK_SENDERS.values.map { |email| "from:#{email}" }.join(' OR ')
    end

    # Process payment-specific messages (more strict filtering)
    def process_payment_message(service, msg)
      raw_msg = service.get_user_message('me', msg.id, format: 'full')
      parsed_data = Gmail::BankEmailParser.parse(raw_msg)
      
      if parsed_data && valid_payment_data?(parsed_data)
        PaymentProcessorJob.perform_later(parsed_data)
        mark_as_processed(service, msg.id)
        Rails.logger.info "✅ Processed payment email: #{parsed_data[:reference]} - R#{parsed_data[:amount]}"
      else
        mark_as_read(service, msg.id)
        Rails.logger.debug "📧 Read but skipped non-payment email"
      end
    rescue => e
      Rails.logger.error "❌ Failed to process message #{msg.id}: #{e.message}"
      mark_as_flagged(service, msg.id)
    end

    # Process all bank notifications (broader processing)
    def process_message(service, msg)
      raw_msg = service.get_user_message('me', msg.id, format: 'full')
      parsed_data = Gmail::BankEmailParser.parse(raw_msg)
      
      if parsed_data
        PaymentProcessorJob.perform_later(parsed_data)
        mark_as_read(service, msg.id)
      end
    end

    def valid_payment_data?(parsed_data)
      parsed_data[:amount].to_f > 0 && 
      parsed_data[:reference].present? &&
      parsed_data[:bank].present?
    end

    def mark_as_processed(service, message_id)
      service.modify_message('me', message_id, 
        remove_label_ids: ['UNREAD', 'INBOX'],
        add_label_ids: ['Processed-Payments']
      )
    end

    def mark_as_read(service, message_id)
      service.modify_message('me', message_id, remove_label_ids: ['UNREAD'])
    end

    def mark_as_flagged(service, message_id)
      service.modify_message('me', message_id,
        remove_label_ids: ['UNREAD'],
        add_label_ids: ['Needs-Review']
      )
    end
  end
end
end