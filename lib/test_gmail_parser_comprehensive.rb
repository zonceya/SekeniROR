# lib/test_gmail_parser_comprehensive.rb
puts "Testing Gmail Parser with All Banks..."
puts "=" * 50

require_relative '../app/services/gmail/bank_email_parser'

# Test all banks with realistic email content
BANK_TESTS = [
  {
    name: "ABSA with ORDER- prefix",
    data: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@absa.co.za' }],
        body: { data: Base64.encode64(<<~EMAIL) }
          Dear Customer, a payment of R100.00 has been received.
          Reference: ORDER-TEST123
          Thank you for banking with ABSA.
        EMAIL
      }
    },
    expected: { bank: 'absa', amount: 100.0, reference: 'TEST123' }
  },
  {
    name: "FNB with REF: prefix", 
    data: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@fnb.co.za' }],
        body: { data: Base64.encode64(<<~EMAIL) }
          FNB Notification: Your account has been credited.
          Credit: R200.00
          Reference: REF-TEST456
          Current balance updated.
        EMAIL
      }
    },
    expected: { bank: 'fnb', amount: 200.0, reference: 'TEST456' }
  },
  {
    name: "Capitec with various prefixes",
    data: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@capitecbank.co.za' }],
        body: { data: Base64.encode64(<<~EMAIL) }
          Capitec Bank Notification
          Amount: R300.00 received.
          Ref: PAYMENT-TEST789
          Your balance has been updated.
        EMAIL
      }
    },
    expected: { bank: 'capitec', amount: 300.0, reference: 'TEST789' }
  },
  {
    name: "TymeBank with ORDER- prefix",
    data: {
      payload: {
        headers: [{ name: 'From', value: 'notifications@tymebank.co.za' }],
        body: { data: Base64.encode64(<<~EMAIL) }
          TymeBank Transaction Alert
          Payment received: R400.00
          Reference: ORDER-TESTABC
          Thank you for banking with TymeBank.
        EMAIL
      }
    },
    expected: { bank: 'tymebank', amount: 400.0, reference: 'TESTABC' }
  }
]

BANK_TESTS.each do |test|
  puts "\nTesting: #{test[:name]}"
  result = Gmail::BankEmailParser.parse(test[:data])
  
  if result
    puts "Result: #{result.inspect}"
    
    # Check each field individually
    bank_ok = result[:bank] == test[:expected][:bank]
    amount_ok = result[:amount] == test[:expected][:amount]
    ref_ok = result[:reference] == test[:expected][:reference]
    
    puts "Bank: #{bank_ok ? '✅' : '❌'} (#{result[:bank]} vs #{test[:expected][:bank]})"
    puts "Amount: #{amount_ok ? '✅' : '❌'} (#{result[:amount]} vs #{test[:expected][:amount]})"
    puts "Reference: #{ref_ok ? '✅' : '❌'} (#{result[:reference]} vs #{test[:expected][:reference]})"
    
    success = bank_ok && amount_ok && ref_ok
    puts success ? "✅ OVERALL: PASS" : "❌ OVERALL: FAIL"
  else
    puts "❌ No result"
  end
end