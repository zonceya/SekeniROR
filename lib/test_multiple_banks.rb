# lib/test_multiple_banks.rb
require File.expand_path('../../config/environment', __FILE__)

puts "Testing Multiple Bank Formats..."
puts "=" * 50

test_emails = [
  {
    name: 'ABSA',
    email: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@absa.co.za' }],
        body: { 
          data: Base64.strict_encode64("Payment of R500.00 Reference: ORDER-12345")
        }
      }
    }
  },
  {
    name: 'FNB',
    email: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@fnb.co.za' }],
        body: { 
          data: Base64.strict_encode64("Credit: R750.50 Reference: ORDER-67890")
        }
      }
    }
  },
  {
    name: 'Capitec', 
    email: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@capitecbank.co.za' }],
        body: { 
          data: Base64.strict_encode64("Amount: R1200.00 Ref: ORDER-54321")
        }
      }
    }
  }
]

test_emails.each do |test|
  puts "\nTesting #{test[:name]}:"
  parsed = Gmail::BankEmailParser.parse(test[:email])
  if parsed
    puts "  Bank: #{parsed[:bank]}"
    puts "  Amount: R#{parsed[:amount]}"
    puts "  Reference: #{parsed[:reference]}"
    puts "  ✅ SUCCESS"
  else
    puts "  ❌ FAILED: Could not parse"
  end
end