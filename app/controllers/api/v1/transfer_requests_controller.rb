# app/controllers/api/v1/transfer_requests_controller.rb
module Api
  module V1
    class TransferRequestsController < BaseController
      before_action :authenticate_user!
      before_action :set_wallet
      before_action :set_transfer_request, only: [:show]

      # GET /api/v1/wallet/transfer_requests
      def index
        transfer_requests = @wallet.transfer_requests.order(created_at: :desc)
        render json: {
          success: true,
          transfer_requests: transfer_requests.as_json(
            except: [:created_at, :updated_at],
            include: {
              bank_account: { except: [:created_at, :updated_at] }
            }
          )
        }
      end

      # GET /api/v1/wallet/transfer_requests/:id
      def show
        render json: {
          success: true,
          transfer_request: @transfer_request.as_json(
            except: [:created_at, :updated_at],
            include: {
              bank_account: { except: [:created_at, :updated_at] }
            }
          )
        }
      end

      # POST /api/v1/wallet/transfer_requests
      def create
        transfer_request = @wallet.transfer_requests.new(transfer_request_params)

        if transfer_request.save
          # Process the transfer asynchronously
          BankTransferJob.perform_later(transfer_request.id)
          
          render json: {
            success: true,
            message: 'Transfer request submitted successfully',
            transfer_request: transfer_request.as_json(
              except: [:created_at, :updated_at],
              include: {
                bank_account: { except: [:created_at, :updated_at] }
              }
            )
          }, status: :created
        else
          render json: {
            success: false,
            errors: transfer_request.errors.full_messages
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

      def set_transfer_request
        @transfer_request = @wallet.transfer_requests.find_by(id: params[:id])
        unless @transfer_request
          render json: {
            success: false,
            error: 'Transfer request not found'
          }, status: :not_found
        end
      end

      def transfer_request_params
        params.require(:transfer_request).permit(
          :bank_account_id,
          :amount
        )
      end
    end
  end
end