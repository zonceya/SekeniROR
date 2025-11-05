# app/jobs/payment_processor_job.rb
class PaymentProcessorJob < ApplicationJob
  def perform(parsed_email)
    order = find_matching_order(parsed_email[:reference])
    
    if order
      if order.total_amount == parsed_email[:amount]
        process_successful_payment(order, parsed_email)
      else
        process_amount_mismatch(order, parsed_email)
      end
    else
      process_order_not_found(parsed_email)
    end
  end

  private

  def find_matching_order(reference)
    # 1. First try exact match (customer used order number directly)
    order = Order.find_by(order_number: reference)
    return order if order

    # 2. Try common bank formats (ORDER- prefix, etc.)
    extracted = extract_pure_order_number(reference)
    Order.find_by(order_number: extracted) if extracted
  end

  def extract_pure_order_number(reference)
    # Remove common bank prefixes/suffixes and extract clean order number
    cleaned = reference.to_s
      .gsub(/^(ORDER|REF|PAYMENT|REFERENCE|TRANSACTION)[\s\-:]*/i, '')  # Remove prefixes
      .gsub(/[\s\-].*$/, '')  # Remove everything after first space/hyphen
      .strip
    
    # Extract what looks like your order number format (4 letters + 10 digits + 2 letters)
    match = cleaned.match(/([A-Z]{4}\d{10}[A-Z]{2})/)
    
    match ? match[1] : cleaned
  end

  def process_successful_payment(order, payment_data)
    ActiveRecord::Base.transaction do
      # Update order status
      order.update!(
        payment_status: :paid,
        paid_at: payment_data[:timestamp] || Time.current,
        bank: payment_data[:bank]
      )
      
      # ✅ NOW THIS WILL WORK - Create transaction record
      OrderTransaction.create!(
        order: order,
        amount: order.total_amount,
        txn_status: :received,
        payment_method: :eft,
        bank_ref_num: payment_data[:reference],
        bank: payment_data[:bank],
        txn_time: payment_data[:timestamp] || Time.current
      )
    end
    
    puts "✅ Payment confirmed for order ##{order.order_number}"
  end

  def process_amount_mismatch(order, payment_data)
    ActiveRecord::Base.transaction do
      # Create flagged payment
      FlaggedPayment.create!(
        order: order,
        expected_amount: order.total_amount,
        received_amount: payment_data[:amount],
        reference: payment_data[:reference],
        bank: payment_data[:bank],
        status: :amount_mismatch
      )
      
      # ✅ NOW THIS WILL WORK - Create transaction record with flagged status
      OrderTransaction.create!(
        order: order,
        amount: payment_data[:amount],
        txn_status: :flagged,
        payment_method: :eft,
        bank_ref_num: payment_data[:reference],
        bank: payment_data[:bank],
        txn_time: payment_data[:timestamp] || Time.current
      )
    end
    
    puts "⚠️ Amount mismatch for order ##{order.order_number}"
  end

  def process_order_not_found(payment_data)
    FlaggedPayment.create!(
      reference: payment_data[:reference],
      received_amount: payment_data[:amount],
      bank: payment_data[:bank],
      status: :order_not_found
    )
    
    puts "❌ Order not found for reference: #{payment_data[:reference]}"
  end
end