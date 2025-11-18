# app/controllers/api/v1/wallets_controller.rb
module Api
  module V1
    class WalletsController < BaseController  # Changed from Api::V1::BaseController
      before_action :authenticate_user!  # Changed from authenticate_request!
      before_action :set_wallet

      def show
        render json: {
          wallet: wallet_summary,
          balance: {
            current: @wallet.current_balance,
            pending: @wallet.pending_balance,
            available: @wallet.available_balance
          }
        }
      end

      def transactions
        transactions = @wallet.wallet_transactions.order(created_at: :desc)
        
        render json: {
          transactions: transactions.map { |t| serialize_transaction(t) },
          pagination: {
            total_count: transactions.count,
            current_page: params[:page] || 1
          }
        }
      end

      private

      def set_wallet
        @wallet = current_user.digital_wallet
        return render json: { error: 'Wallet not found' }, status: :not_found unless @wallet
      end

      def wallet_summary
        {
          id: @wallet.id,
          wallet_number: @wallet.wallet_number,
          user_id: @wallet.user_id,
          created_at: @wallet.created_at
        }
      end

      def serialize_transaction(transaction)
        {
          id: transaction.id,
          amount: transaction.amount,
          net_amount: transaction.net_amount,
          transaction_type: transaction.transaction_type,
          status: transaction.status,
          transaction_source: transaction.transaction_source,
          description: transaction.description,
          service_fee: transaction.service_fee,
          insurance_fee: transaction.insurance_fee,
          order_number: transaction.order&.order_number,
          created_at: transaction.created_at,
          metadata: transaction.metadata
        }
      end
    end
  end
end