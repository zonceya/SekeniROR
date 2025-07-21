# app/serializers/order_payment_serializer.rb
class OrderPaymentSerializer
  include FastJsonapi::ObjectSerializer
  
  attributes :order_id, :amount_due, :currency, :reference, :instructions, :expires_at, :countdown_seconds
  
  attribute :bank_details do |object|
    {
      account_name: "Sekeni Pty Ltd",
      account_number: "1234567890",
      bank_name: "Capitec Bank",
      branch_code: "470010"
    }
  end
end