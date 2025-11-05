# lib/test_bank_parsing.rb

# FIXED: Use require instead of require_relative with correct path
require File.expand_path('../../config/environment', __FILE__)

module SampleBankEmails
  def self.samples
    {
      absa: {
        from: 'notifications@absa.co.za',
        body: <<~EMAIL
          Dear Customer,
          You have received a payment of R500.00 from JOHN DOE.
          Reference: ORDER-12345
          Date: #{Time.current.strftime('%Y-%m-%d')}
        EMAIL
      },
      fnb: {
        from: 'notifications@fnb.co.za', 
        body: <<~EMAIL
          FNB Notification:
          Credit: R750.50  
          Reference: ORDER-67890
          Available Balance: R12,345.67
        EMAIL
      },
      capitec: {
        from: 'notifications@capitecbank.co.za',
        body: <<~EMAIL
          Capitec Bank Notification:
          Amount: R1,200.00
          Ref: ORDER-54321
          Time: #{Time.current.strftime('%H:%M')}
        EMAIL
      }
    }
  end
end

class BankEmailParser
  def self.parse(raw_email)
    body = if raw_email[:payload] && raw_email[:payload][:body] && raw_email[:payload][:body][:data]
             Base64.decode64(raw_email[:payload][:body][:data])
           else
             ''
           end

    from_header = raw_email[:payload][:headers].find { |h| h[:name] == 'From' }
    return unless from_header

    bank = if from_header[:value].include?('absa')
             'absa'
           elsif from_header[:value].include?('fnb')
             'fnb'
           elsif from_header[:value].include?('capitec')
             'capitec'
           end

    return unless bank

    {
      bank: bank,
      amount: extract_amount(bank, body),
      reference: extract_reference(bank, body),
      timestamp: Time.current
    }
  end

  private

  def self.extract_amount(bank, body)
    case bank
    when 'absa'
      body.match(/payment of R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
    when 'fnb'
      body.match(/Credit: R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
    when 'capitec'
      body.match(/Amount: R([\d,]+\.\d{2})/i)&.captures&.first&.gsub(',', '')&.to_f
    end
  end

  def self.extract_reference(bank, body)
    case bank
    when 'absa'
      body.match(/Reference: (\S+)/i)&.captures&.first
    when 'fnb'
      body.match(/Reference: (\S+)/i)&.captures&.first
    when 'capitec'
      body.match(/Ref: (\S+)/i)&.captures&.first
    end
  end
end

puts "Testing Bank Email Parsing..."
puts "=" * 50

SampleBankEmails.samples.each do |bank, data|
  fake_email = {
    payload: {
      headers: [
        { name: 'From', value: data[:from] },
        { name: 'Date', value: Time.current.rfc2822 }
      ],
      body: { data: Base64.strict_encode64(data[:body]) }
    }
  }

  parsed = BankEmailParser.parse(fake_email)
  
  puts "Bank: #{bank.upcase}"
  puts "Amount: R#{parsed[:amount]}"
  puts "Reference: #{parsed[:reference]}"
  puts "Status: #{parsed[:amount] && parsed[:reference] ? '✅ SUCCESS' : '❌ FAILED'}"
  puts "-" * 30
end