module Inventory
  class HoldService
    HOLD_DURATION = 24.hours # Longer hold for bank transfers

    def initialize(item:, user:, quantity: 1)
      @item = item
      @user = user
      @quantity = quantity
    end

    def call
      ActiveRecord::Base.transaction do
        validate_availability!
        create_hold!
      end
    rescue => e
      OpenStruct.new(success?: false, error: e.message)
    end

    private

    def validate_availability!
      unless @item.can_fulfill?(@quantity)
        raise "Not enough inventory (Available: #{@item.available_quantity}, Requested: #{@quantity})"
      end
    end

    def create_hold!
      @item.with_lock do
        @item.increment!(:reserved, @quantity)
        Hold.create!(
          item: @item,
          user: @user,
          quantity: @quantity,
          expires_at: Time.current + HOLD_DURATION,
          status: :awaiting_payment
        )
      end
      OpenStruct.new(success?: true, hold: @item.holds.last)
    end
  end
end