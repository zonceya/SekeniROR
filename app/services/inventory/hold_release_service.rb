# app/services/inventory/hold_release_service.rb
module Inventory
  class HoldReleaseService
    def initialize(hold)
      @hold = hold
    end

    def call
      return unless @hold.status_awaiting_payment?

      ActiveRecord::Base.transaction do
        release_inventory!
        @hold.update!(status: :expired) unless @hold.status_expired?
        true
      end
    rescue => e
      Rails.logger.error "Failed to release hold #{@hold.id}: #{e.message}"
      false
    end

    private

    def release_inventory!
      @hold.item.with_lock do
        @hold.item.decrement!(:reserved, @hold.quantity)
      end
    end
  end
end