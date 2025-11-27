# app/services/wallet_service.rb
class WalletService
  SERVICE_FEE_PERCENTAGE = 0.05  # 5% service fee to SkoolSwap
  INSURANCE_FEE_AMOUNT = 10.00   # R10 insurance fee to SkoolSwap

  def self.credit_seller_for_order_completion(order)
    seller_wallet = order.shop.user.digital_wallet
    
    ActiveRecord::Base.transaction do
      # Calculate fees that go to SkoolSwap
      service_fee = order.total_amount * SERVICE_FEE_PERCENTAGE
      total_fees = service_fee + INSURANCE_FEE_AMOUNT
      
      # Amount that actually goes to seller (item amount minus fees)
      seller_amount = order.total_amount - total_fees

      # Credit seller with the item amount (minus our fees)
      seller_wallet.wallet_transactions.create!(
        amount: seller_amount,
        net_amount: seller_amount,
        transaction_type: 'credit',
        status: 'completed',
        transaction_source: 'order_payment',
        order: order,
        description: "Payment for Order ##{order.order_number} (after fees)"
      )

      # Record fees as debits from seller (these go to SkoolSwap)
      seller_wallet.wallet_transactions.create!(
        amount: service_fee,
        net_amount: -service_fee,
        transaction_type: 'debit',
        status: 'completed',
        transaction_source: 'service_fee',
        order: order,
        description: "Service fee for Order ##{order.order_number}"
      )

      seller_wallet.wallet_transactions.create!(
        amount: INSURANCE_FEE_AMOUNT,
        net_amount: -INSURANCE_FEE_AMOUNT,
        transaction_type: 'debit',
        status: 'completed',
        transaction_source: 'insurance_fee',
        order: order,
        description: "Insurance fee for Order ##{order.order_number}"
      )

      # In a real system, you'd also credit SkoolSwap's wallet here
      # credit_skoolswap_wallet(total_fees, order)
    end
  end

  def self.hold_buyer_funds(order)
    buyer_wallet = order.buyer.digital_wallet
    
    transaction = buyer_wallet.wallet_transactions.create!(
      amount: order.total_amount,
      net_amount: -order.total_amount,
      transaction_type: 'debit',
      status: 'pending',
      transaction_source: 'order_payment',
      order: order,
      description: "Reserved for Order ##{order.order_number}"
    )

    transaction
  end

  def self.release_buyer_hold(order)
    transaction = order.wallet_transactions
                      .where(transaction_type: 'debit', status: 'pending')
                      .first
    transaction&.update(status: 'failed', description: "Hold released for Order ##{order.order_number}")
  end

  def self.process_transfer_request(transfer_request, admin_user = nil)
    ActiveRecord::Base.transaction do
      transfer_request.update!(
        status: 'processing',
        processed_at: Time.current
      )

      # Simulate bank transfer processing
      if simulate_bank_transfer(transfer_request)
        transfer_request.update!(status: 'completed')
        transfer_request.wallet_transaction.update!(
          status: 'completed',
          description: "Bank transfer completed to #{transfer_request.bank_account.bank_name}"
        )
        
        # Send notification
        NotificationService.transfer_completed(transfer_request)
        true
      else
        transfer_request.update!(status: 'failed')
        transfer_request.wallet_transaction.update!(
          status: 'failed', 
          description: "Bank transfer failed to #{transfer_request.bank_account.bank_name}"
        )
        
        NotificationService.transfer_failed(transfer_request)
        false
      end
    end
  end
   def self.admin_top_up(wallet, amount, admin_user = nil)
    ActiveRecord::Base.transaction do
      transaction = wallet.wallet_transactions.create!(
        amount: amount,
        net_amount: amount,
        transaction_type: 'credit',
        status: 'completed',
        transaction_source: 'admin_topup',
        description: "Admin top-up of R#{amount}"
      )

      # Log the admin action if admin_user is provided
      if admin_user
        # You might want to create an AdminAction model for logging
        Rails.logger.info "Admin top-up: R#{amount} added to wallet #{wallet.id} by admin #{admin_user.id}"
      end

      transaction
    end
  end

  private

  def self.simulate_bank_transfer(transfer_request)
    # Simulate processing - 95% success rate for demo
    rand > 0.05
  end

  # Optional: Method to credit SkoolSwap's system wallet
  def self.credit_skoolswap_wallet(amount, order)
    # This would credit your company's wallet with the fees
    # skoolswap_wallet = DigitalWallet.find_by(user_id: SKOOLSWAP_ADMIN_ID)
    # skoolswap_wallet.wallet_transactions.create!(...)
  end
end