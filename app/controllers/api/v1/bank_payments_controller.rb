module Api
  module V1
    class BankPaymentsController < ApplicationController
      before_action :authenticate_user!

      def create
        @item = Item.find(params[:item_id])

        result = Inventory::HoldService.new(
          item: @item,
          user: current_user,
          quantity: params[:quantity] || 1
        ).call

        if result.success?
          order = create_pending_order(result.hold)
          redirect_to bank_transfer_instructions_path(order)
        else
          flash[:error] = result.error
          redirect_to item_path(@item)
        end
      end

      private

      def create_pending_order(hold)
        Order.create!(
          buyer: current_user,
          shop: hold.item.shop,
          order_status: :pending_payment,
          payment_status: :unpaid,
          order_items_attributes: [{
            item: hold.item,
            quantity: hold.quantity,
            actual_price: hold.item.price
          }]
        ).tap do |order|
          hold.update!(order: order)
        end
      end
    end
  end
end