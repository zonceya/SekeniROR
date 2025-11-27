module Api
  module V1
    class BankAccountsController < BaseController
      before_action :authenticate_user!
      before_action :set_wallet
      before_action :set_bank_account, only: [:show, :update, :destroy]

      def index
        bank_accounts = @wallet.bank_accounts
        render json: {
          success: true,
          bank_accounts: bank_accounts.as_json(except: [:created_at, :updated_at])
        }
      end

      def show
        render json: {
          success: true,
          bank_account: @bank_account.as_json(except: [:created_at, :updated_at])
        }
      end

      def create
        bank_account = @wallet.bank_accounts.new(bank_account_params)

        if bank_account.save
          render json: {
            success: true,
            message: 'Bank account added successfully',
            bank_account: bank_account.as_json(except: [:created_at, :updated_at])
          }, status: :created
        else
          render json: {
            success: false,
            errors: bank_account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        if @bank_account.update(bank_account_params)
          render json: {
            success: true,
            message: 'Bank account updated successfully',
            bank_account: @bank_account.as_json(except: [:created_at, :updated_at])
          }
        else
          render json: {
            success: false,
            errors: @bank_account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        if @bank_account.destroy
          render json: {
            success: true,
            message: 'Bank account removed successfully'
          }
        else
          render json: {
            success: false,
            errors: @bank_account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_wallet
        @wallet = current_user.digital_wallet
        unless @wallet
          render json: {
            success: false,
            error: 'Wallet not found'
          }, status: :not_found
        end
      end

      def set_bank_account
        @bank_account = @wallet.bank_accounts.find_by(id: params[:id])
        unless @bank_account
          render json: {
            success: false,
            error: 'Bank account not found'
          }, status: :not_found
        end
      end

      def bank_account_params
        params.require(:bank_account).permit(
          :account_holder_name,
          :bank_name,
          :account_number,
          :branch_code,
          :account_type
        )
      end
    end
  end
end