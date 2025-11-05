# lib/test_gmail_parser_real.rb
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
    name: "FNB Credit Notification",
    data: {
      payload: {
        headers: [
          { name: 'From', value: 'notifications@fnb.co.za' },
          { name: 'Date', value: 'Mon, 27 Aug 2024 15:45:22 +0200' }
        ],
        body: {
          data: Base64.encode64(<<~EMAIL)
            FNB Notification: Account Credit
            
            Your account has been credited with R2,850.50.
            
            Details:
            Credit: R2,850.50
            Reference: SHOP0827154522AB
            Balance: R15,234.67
            
            Thank you for using FNB.
          EMAIL
        }
      }
    },
    expected: {
      bank: 'fnb',
      amount: 2850.50,
      reference: 'SHOP0827154522AB'
    }
  },
  {
    name: "Capitec Payment Received",
    data: {
      payload: {
        headers: [
          { name: 'From', value: 'notifications@capitecbank.co.za' },
          { name: 'Date', value: 'Mon, 27 Aug 2024 16:20:33 +0200' }
        ],
        body: {
          data: Base64.encode64(<<~EMAIL)
            Capitec Bank Notification
            
            Amount: R750.25 received.
            Ref: TEST0827162033CD
            Date: 27/08/2024 16:20
            
            Your available balance has been updated.
            
            Regards,
            Capitec Bank
          EMAIL
        }
      }
    },
    expected: {
      bank: 'capitec',
      amount: 750.25,
      reference: 'TEST0827162033CD'
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
      reference: 'ABCD0827170518ZZ' # Should extract without ORDER- prefix
    }
  },
  {
    name: "Bank with ORDER- prefix",
    data: {
      payload: {
        headers: [
          { name: 'From', value: 'notifications@absa.co.za' },
          { name: 'Date', value: 'Mon, 27 Aug 2024 18:40:12 +0200' }
        ],
        body: {
          data: Base64.encode64(<<~EMAIL)
            ABSA Payment Notification
            
            Payment of R3,999.00 received.
            Reference: ORDER-SEKE0827184012EF
            Transaction completed successfully.
          EMAIL
        }
      }
    },
    expected: {
      bank: 'absa',
      amount: 3999.00,
      reference: 'SEKE0827184012EF' # Should extract without ORDER- prefix
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

def test_order_matching
  puts "\n\nTesting Order Matching Logic:"
  puts "-" * 40
  
  # Create test orders with different formats
  test_orders = [
    { order_number: "SEKE0827143045XY", amount: 1499.99 },
    { order_number: "SHOP0827154522AB", amount: 2850.50 },
    { order_number: "TEST0827162033CD", amount: 750.25 },
    { order_number: "ABCD0827170518ZZ", amount: 1200.00 },
    { order_number: "SEKE0827184012EF", amount: 3999.00 }
  ]
  
  # Create orders in database
  test_orders.each do |order_data|
    Order.create!(
      order_number: order_data[:order_number],
      total_amount: order_data[:amount],
      buyer_id: User.first.id, # Assuming you have at least one user
      shop_id: Shop.first.id,  # Assuming you have at least one shop
      price: order_data[:amount],
      payment_status: :unpaid
    )
  end
  
  # Test order matching with different reference formats
  test_cases = [
    { reference: "SEKE0827143045XY", expected: "SEKE0827143045XY" },
    { reference: "ORDER-SHOP0827154522AB", expected: "SHOP0827154522AB" },
    { reference: "REF:TEST0827162033CD", expected: "TEST0827162033CD" },
    { reference: "PAYMENT ABCD0827170518ZZ", expected: "ABCD0827170518ZZ" },
    { reference: "REFERENCE: SEKE0827184012EF", expected: "SEKE0827184012EF" }
  ]
  
  test_cases.each do |test_case|
    puts "\nTesting reference: '#{test_case[:reference]}'"
    
    order = PaymentProcessorJob.new.send(:find_matching_order, test_case[:reference])
    
    if order
      puts "   ✅ ORDER FOUND: ##{order.order_number} (R#{order.total_amount})"
      if order.order_number == test_case[:expected]
        puts "   ✅ REFERENCE MATCHES EXPECTED: #{test_case[:expected]}"
      else
        puts "   ❌ REFERENCE MISMATCH: Got #{order.order_number}, Expected #{test_case[:expected]}"
      end
    else
      puts "   ❌ ORDER NOT FOUND for reference: #{test_case[:reference]}"
    end
  end
  
  # Cleanup test orders
  test_orders.each { |o| Order.find_by(order_number: o[:order_number])&.destroy }
end

def test_full_payment_flow
  puts "\n\nTesting Full Payment Flow:"
  puts "-" * 30
  
  # Create a test order
  test_order = Order.create!(
    order_number: "TEST0827190000XX",
    total_amount: 500.00,
    buyer_id: User.first.id,
    shop_id: Shop.first.id,
    price: 500.00,
    payment_status: :unpaid
  )
  
  puts "Created test order: ##{test_order.order_number} (R#{test_order.total_amount})"
  
  # Simulate payment email
  payment_email = {
    bank: 'absa',
    amount: 500.00,
    reference: 'TEST0827190000XX',
    timestamp: Time.current
  }
  
  puts "Processing payment: R#{payment_email[:amount]} from #{payment_email[:bank]}"
  
  # Process payment
  PaymentProcessorJob.new.perform(payment_email)
  
  # Check results
  test_order.reload
  puts "Order payment status: #{test_order.payment_status}"
  puts "Paid at: #{test_order.paid_at}"
  puts "Bank: #{test_order.bank}"
  
  # Check transaction record
  transaction = test_order.order_transactions.last
  if transaction
    puts "Transaction created:"
    puts "  Amount: R#{transaction.amount}"
    puts "  Status: #{transaction.txn_status}"
    puts "  Bank Ref: #{transaction.bank_ref_num}"
  else
    puts "❌ No transaction record created"
  end
  
  # Cleanup
  test_order.destroy
end

# Run the tests
begin
  test_email_parsing
  test_order_matching
  test_full_payment_flow
  
  puts "\n" + "=" * 50
  puts "Gmail Parser Test Completed!"
rescue => e
  puts "\n❌ TEST FAILED WITH ERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end