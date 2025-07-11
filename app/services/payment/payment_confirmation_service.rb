module Payments
  class BankTransferConfirmationService
    def initialize(order)
      @order = order
    end

    def call
      ActiveRecord::Base.transaction do
        confirm_payment!
        convert_hold_to_reservation!
      end
      OpenStruct.new(success?: true, order: @order)
    rescue => e
      OpenStruct.new(success?: false, error: e.message)
    end

    private

    def confirm_payment!
      @order.update!(
        order_status: :payment_received,
        payment_status: :paid,
        paid_at: Time.current
      )
    end

    def convert_hold_to_reservation!
      hold = Hold.find_by(item_id: @order.order_items.pluck(:item_id), user: @order.buyer)
      return unless hold

      hold.update!(
        status: :payment_received,
        converted_at: Time.current
      )
    end
  end
end