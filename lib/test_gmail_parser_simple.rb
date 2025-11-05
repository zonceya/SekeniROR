# lib/test_gmail_parser_simple.rb
puts "Testing Gmail Parser with Real Email Data..."
puts "=" * 50

# Load the BankEmailParser from the correct location
require_relative '../app/services/gmail/bank_email_parser'

# Sample real email data from different banks
REAL_EMAIL_SAMPLES = [
  {
    name: "ABSA Payment Notification",
    data: {
      payload: {
        headers: [
          { name: 'From', value: 'notifications@absa.co.za' },
          { name: 'Date', value: 'Mon, 27 Aug 2024 14:30:45 +0200' }
        ],
        body: {
          data: Base64.encode64(<<~EMAIL)
            Dear Valued Customer,
            
            We are pleased to inform you that a payment of R1,499.99 has been received in your account.
            
            Transaction Details:
            - Amount: R1,499.99
            - Reference: SEKE0827143045XY
            - Date: 27 August 2024
            - Time: 14:30:45
            
            Thank you for banking with ABSA.
            
            Kind regards,
            ABSA Team
          EMAIL
        }
      }
    },
    expected: {
      bank: 'absa',
      amount: 1499.99,
      reference: 'SEKE0827143045XY'
    }
  },
  {
    name: "TymeBank Payment",
    data: {
      payload: {
        headers: [
          { name: 'From', value: 'notifications@tymebank.co.za' },
          { name: 'Date', value: 'Mon, 27 Aug 2024 17:05:18 +0200' }
        ],
        body: {
          data: Base64.encode64(<<~EMAIL)
            TymeBank Transaction Alert
            
            Payment received: R1,200.00
            Reference: ORDER-ABCD0827170518ZZ
            Time: 17:05:18
            
            Thank you for banking with TymeBank.
          EMAIL
        }
      }
    },
    expected: {
      bank: 'tymebank',
      amount: 1200.00,
      reference: 'ABCD0827170518ZZ'
    }
  }
]

def test_email_parsing
  puts "Testing Bank Email Parser with Real Samples:"
  puts "-" * 60
  
  REAL_EMAIL_SAMPLES.each_with_index do |sample, index|
    puts "\n#{index + 1}. #{sample[:name]}"
    puts "   Expected: #{sample[:expected][:bank]}, R#{sample[:expected][:amount]}, Ref: #{sample[:expected][:reference]}"
    
    result = Gmail::BankEmailParser.parse(sample[:data])
    
    if result
      puts "   ✅ PARSED: #{result[:bank]}, R#{result[:amount]}, Ref: #{result[:reference]}"
      
      # Check if parsing matches expected results
      success = true
      success &&= result[:bank] == sample[:expected][:bank]
      success &&= result[:amount] == sample[:expected][:amount]
      success &&= result[:reference] == sample[:expected][:reference]
      
      if success
        puts "   ✅ ALL VALUES MATCH EXPECTED!"
      else
        puts "   ❌ SOME VALUES DON'T MATCH:"
        puts "      Bank: #{result[:bank]} vs #{sample[:expected][:bank]}" unless result[:bank] == sample[:expected][:bank]
        puts "      Amount: R#{result[:amount]} vs R#{sample[:expected][:amount]}" unless result[:amount] == sample[:expected][:amount]
        puts "      Reference: #{result[:reference]} vs #{sample[:expected][:reference]}" unless result[:reference] == sample[:expected][:reference]
      end
    else
      puts "   ❌ FAILED TO PARSE EMAIL"
    end
  end
end

# Run the test
begin
  test_email_parsing
  puts "\n" + "=" * 50
  puts "Gmail Parser Test Completed!"
rescue => e
  puts "\n❌ TEST FAILED WITH ERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end