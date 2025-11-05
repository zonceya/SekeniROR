# app/services/gmail/bank_email_parser.rb
module Gmail
  class BankEmailParser
    BANK_SENDERS = {
      'absa' => 'notifications@absa.co.za',
      'fnb' => 'notifications@fnb.co.za',
      'capitec' => 'notifications@capitecbank.co.za',
      'tymebank' => 'notifications@tymebank.co.za'
    }

    def self.parse(raw_email)
      body = extract_body(raw_email)
      bank = identify_bank(raw_email)

      return unless bank

      parsed_data = {
        bank: bank,
        amount: extract_amount(bank, body),
        reference: extract_reference(bank, body),
        timestamp: extract_timestamp(raw_email),
        sender_email: extract_sender(raw_email),
        subject: extract_subject(raw_email),
        email_date: extract_date(raw_email)
      }
      
      # Clean up the reference by removing common prefixes
      parsed_data[:reference] = clean_reference(parsed_data[:reference]) if parsed_data[:reference]
      
      # Only return if it looks like a valid payment
      if parsed_data[:amount].to_f > 0 && parsed_data[:reference].present?
        parsed_data
      end
    end

    def self.extract_reference(bank, body)
      case bank
      when 'absa'
        body.match(/Reference:[\s]*(\S+)/i)&.captures&.first ||
        body.match(/Ref:[\s]*(\S+)/i)&.captures&.first
      when 'fnb'
        body.match(/Reference:[\s]*(\S+)/i)&.captures&.first ||
        body.match(/Ref:[\s]*(\S+)/i)&.captures&.first
      when 'capitec'
        body.match(/Reference:[\s]*(\S+)/i)&.captures&.first ||
        body.match(/Ref:[\s]*(\S+)/i)&.captures&.first
      when 'tymebank'
        body.match(/Reference:[\s]*(\S+)/i)&.captures&.first ||
        body.match(/Ref:[\s]*(\S+)/i)&.captures&.first
      end
    end

    def self.clean_reference(reference)
      return unless reference
      reference.gsub(/^(ORDER|REF|PAYMENT|REFERENCE|TRANSACTION)[\s\-:]*/i, '')
    end

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

    private_class_method def self.extract_body(raw_email)
      if raw_email[:payload] && raw_email[:payload][:body] && raw_email[:payload][:body][:data]
        Base64.urlsafe_decode64(raw_email[:payload][:body][:data])
      else
        # Try to get body from parts if not in main body
        extract_body_from_parts(raw_email[:payload][:parts]) if raw_email[:payload] && raw_email[:payload][:parts]
      end
    rescue => e
      Rails.logger.error "Failed to extract email body: #{e.message}"
      ''
    end

    private_class_method def self.extract_body_from_parts(parts)
      parts.each do |part|
        if part[:mime_type] == 'text/plain' && part[:body] && part[:body][:data]
          return Base64.urlsafe_decode64(part[:body][:data])
        elsif part[:parts]
          result = extract_body_from_parts(part[:parts])
          return result if result.present?
        end
      end
      ''
    end

    private_class_method def self.identify_bank(raw_email)
      from_header = raw_email[:payload][:headers].find { |h| h[:name] == 'From' }
      return unless from_header

      BANK_SENDERS.each do |bank, email|
        return bank if from_header[:value].include?(email)
      end

      nil
    end

    private_class_method def self.extract_amount(bank, body)
      case bank
      when 'absa'
        body.match(/payment of R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
      when 'fnb'
        body.match(/Credit: R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
      when 'capitec'
        body.match(/Amount: R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
      when 'tymebank'
        body.match(/Payment received: R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f ||
        body.match(/received: R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
      end
    end

    private_class_method def self.extract_timestamp(raw_email)
      date_header = raw_email[:payload][:headers].find { |h| h[:name] == 'Date' }
      date_header ? Time.parse(date_header[:value]) : Time.current
    end
  end
end