# app/services/gmail/bank_processor.rb
module Gmail
  class BankProcessor
    def self.process_email(raw_email)
      # Implementation here
      # You can delegate to BankEmailParser if needed
      Gmail::BankEmailParser.parse(raw_email)
    end
  end
end