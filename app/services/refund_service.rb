# app/services/refund_service.rb
class RefundService
  CANCEL_REASONS = [
    'item_not_as_described',
    'damaged',
    'wrong_item',
    'fake_counterfeit',
    'seller_did_not_arrive',
    'unsafe_meet_up',
    'changed_mind'
  ]

  def self.process_buyer_cancellation(order, params)
    puts "🔧 DEBUG: Starting refund process for order #{order.id}"
    
    # Validate reason first
    unless CANCEL_REASONS.include?(params[:reason])
      puts "❌ DEBUG: Invalid cancellation reason: #{params[:reason]}"
      return { success: false, errors: ["Invalid cancellation reason"] }
    end
    puts "✅ DEBUG: Reason validated: #{params[:reason]}"

    begin
      ActiveRecord::Base.transaction do
        puts "🔧 DEBUG: Transaction started"
        
        # Step 1: Create refund
        puts "🔧 DEBUG: Creating refund record..."
        refund = Refund.create!(
          order: order,
          amount: order.total_amount,
          reason: params[:reason],
          refund_type: 'buyer_cancellation',
          status: 'processing',
          processed_by: order.buyer,
          estimated_completion: 2.hours.from_now
        )
        puts "✅ DEBUG: Refund created: #{refund.id}"

        # Step 2: Update order
        puts "🔧 DEBUG: Updating order status..."
        order.update!(
          order_status: 'cancelled',
          cancellation_reason: params[:reason],
          cancelled_at: Time.current
        )
        puts "✅ DEBUG: Order updated to cancelled"

        # Step 3: Cancel any active PINs
        puts "🔧 DEBUG: Cancelling active PINs..."
        order.pin_verifications.active.update_all(status: 'cancelled')
        puts "✅ DEBUG: PINs cancelled"

        # Step 4: Process wallet refund
        puts "🔧 DEBUG: Processing wallet refund..."
        wallet_result = process_wallet_refund(refund)
        puts "✅ DEBUG: Wallet refund processed"

        # Step 5: Apply seller strike
        puts "🔧 DEBUG: Applying seller strike..."
        strike_result = apply_seller_strike(order.shop.user, params[:reason])
        puts "✅ DEBUG: Seller strike applied"

        puts "🎉 DEBUG: Transaction completed successfully!"
        { success: true, refund: refund }
      end
    rescue => e
      puts "❌ DEBUG: Transaction failed with error: #{e.message}"
      puts "❌ DEBUG: Backtrace: #{e.backtrace.first(5).join("\n")}"
      { success: false, errors: [e.message] }
    end
  end

  def self.process_wallet_refund(refund)
    puts "🔧 DEBUG: Starting wallet refund process"
    buyer_wallet = refund.order.buyer.digital_wallet
    
    unless buyer_wallet
      puts "❌ DEBUG: Buyer has no digital wallet"
      raise "Buyer does not have a digital wallet"
    end
    puts "✅ DEBUG: Buyer wallet found: #{buyer_wallet.id}"

    puts "🔧 DEBUG: Creating wallet transaction..."
    transaction = WalletTransaction.create!(
      digital_wallet: buyer_wallet,
      order: refund.order,
      amount: refund.amount,
      net_amount: refund.amount,
      transaction_type: 'credit',
      status: 'completed',
      transaction_source: 'refund',
      description: "Refund for cancelled Order ##{refund.order.order_number}"
    )
    puts "✅ DEBUG: Wallet transaction created: #{transaction.id}"

    puts "🔧 DEBUG: Updating refund status..."
    refund.update!(
      status: 'completed',
      processed_at: Time.current,
      wallet_transaction: transaction
    )
    puts "✅ DEBUG: Refund updated to completed"

    transaction
  end

  def self.apply_seller_strike(seller, reason)
    puts "🔧 DEBUG: Creating seller strike..."
    strike = SellerStrike.create!(
      seller: seller,
      reason: reason,
      severity: calculate_strike_severity(reason),
      expires_at: 1.week.from_now
    )
    puts "✅ DEBUG: Seller strike created: #{strike.id}"

    strike
  end

  def self.calculate_strike_severity(reason)
    case reason
    when 'fake_counterfeit', 'unsafe_meet_up'
      'high'
    when 'seller_did_not_arrive', 'damaged'
      'medium'
    else
      'low'
    end
  end
end