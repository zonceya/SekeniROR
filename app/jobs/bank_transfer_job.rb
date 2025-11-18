# app/jobs/bank_transfer_job.rb
class BankTransferJob < ApplicationJob
  queue_as :default

  def perform(transfer_request_id)
    transfer_request = TransferRequest.find_by(id: transfer_request_id)
    return unless transfer_request && transfer_request.pending?

    # Simulate bank transfer processing
    if simulate_bank_transfer(transfer_request)
      transfer_request.update!(
        status: :completed,
        processed_at: Time.current
      )
      transfer_request.wallet_transaction.update!(
        status: :completed,
        description: "Bank transfer completed to #{transfer_request.bank_account.bank_name}"
      )
    else
      transfer_request.update!(
        status: :failed,
        processed_at: Time.current
      )
      transfer_request.wallet_transaction.update!(
        status: :failed,
        description: "Bank transfer failed to #{transfer_request.bank_account.bank_name}"
      )
    end
  end

  private

  def simulate_bank_transfer(transfer_request)
    # Simulate processing - 95% success rate for demo
    rand > 0.05
  end
end