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
        timestamp: extract_timestamp(raw_email)
      }
      
      # Clean up the reference by removing common prefixes
      parsed_data[:reference] = clean_reference(parsed_data[:reference]) if parsed_data[:reference]
      
      parsed_data
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
      # Remove common bank prefixes like ORDER-, REF:, etc.
      reference.gsub(/^(ORDER|REF|PAYMENT|REFERENCE|TRANSACTION)[\s\-:]*/i, '')
    end

    private

    def self.extract_body(raw_email)
      if raw_email[:payload] && raw_email[:payload][:body] && raw_email[:payload][:body][:data]
        Base64.decode64(raw_email[:payload][:body][:data])
      else
        ''
      end
    end

    def self.identify_bank(raw_email)
      from_header = raw_email[:payload][:headers].find { |h| h[:name] == 'From' }
      return unless from_header

      BANK_SENDERS.each do |bank, email|
        return bank if from_header[:value].include?(email)
      end

      nil
    end

    def self.extract_amount(bank, body)
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

    def self.extract_timestamp(raw_email)
      date_header = raw_email[:payload][:headers].find { |h| h[:name] == 'Date' }
      date_header ? Time.parse(date_header[:value]) : Time.current
    end
  end
end