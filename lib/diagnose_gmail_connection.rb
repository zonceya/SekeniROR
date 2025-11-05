# lib/diagnose_gmail_connection.rb
require 'google/apis/gmail_v1'
require 'googleauth'
require 'stringio'

puts "🔍 Starting Gmail Connection Diagnosis..."
puts "Rails Environment: #{Rails.env}"

begin
  # Check if credentials exist
  unless Rails.application.credentials.google_service_account
    puts "❌ ERROR: Google Service Account credentials not found in credentials.yml.enc"
    puts "Please add: google_service_account: { ... }"
    exit 1
  end

  puts "✅ Google Service Account credentials found"

  # Initialize credentials
  credentials = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: StringIO.new(Rails.application.credentials.google_service_account.to_json),
    scope: ['https://www.googleapis.com/auth/gmail.readonly']
  )

  puts "✅ Credentials initialized successfully"

  # Initialize service
  service = Google::Apis::GmailV1::GmailService.new
  service.authorization = credentials

  puts "✅ Gmail service initialized"

  # Test connection by listing labels
  labels = service.list_user_labels('me')
  puts "✅ Connection successful! Found #{labels.labels.size} labels"

  # List some labels for verification
  puts "\n📧 Available Labels:"
  labels.labels.first(10).each do |label|
    puts "  - #{label.name} (ID: #{label.id})"
  end

  # Test query building
  bank_emails = [
    'notifications@absa.co.za',
    'notifications@fnb.co.za',
    'notifications@capitecbank.co.za',
    'notifications@standardbank.co.za',
    'notifications@nedbank.co.za',
    'notifications@tymebank.co.za'
  ]

  bank_query = bank_emails.map { |email| "from:#{email}" }.join(' OR ')
  payment_query = "#{bank_query} AND (subject:payment OR subject:deposit OR subject:transfer OR subject:credit OR subject:eft) AND is:unread"

  puts "\n🔍 Sample Queries:"
  puts "Bank Query: #{bank_query}"
  puts "Payment Query: #{payment_query}"

  # Test message fetching (just count)
  messages = service.list_user_messages('me', q: bank_query, max_results: 5)
  puts "✅ Found #{messages.messages&.size || 0} messages matching bank query"

  puts "\n🎉 Gmail connection test completed successfully!"

rescue Google::Apis::AuthorizationError => e
  puts "❌ AUTHORIZATION ERROR: #{e.message}"
  puts "Check your service account credentials and ensure they have Gmail API access"
  puts "Ensure the service account has domain-wide delegation if needed"

rescue Google::Apis::ClientError => e
  puts "❌ CLIENT ERROR: #{e.message}"
  puts "Check your API quotas and permissions"

rescue StandardError => e
  puts "❌ UNEXPECTED ERROR: #{e.class.name} - #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5).join("\n")
end