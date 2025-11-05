# app/services/gmail/bank_email_parser.rb
module Gmail
  class BankEmailParser
    def self.parse_from_raw(from:, body:, date:)
      bank = identify_bank(from)
      return unless bank

      {
        bank: bank,
        amount: extract_amount(bank, body),
        reference: extract_reference(bank, body),
        timestamp: date || Time.current
      }
    end

    private

    def self.identify_bank(from_email)
      BANK_SENDERS.each do |bank, email|
        return bank if from_email.include?(email)
      end
      nil
    end

    # ... keep your existing extract_amount and extract_reference methods
  end
end