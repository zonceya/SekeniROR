# db/migrate/20250827000000_add_awaiting_verification_to_order_payment_status.rb
class AddAwaitingVerificationToOrderPaymentStatus < ActiveRecord::Migration[7.0]
  def up
    # For PostgreSQL
    execute <<-SQL
      ALTER TYPE order_payment_status ADD VALUE 'awaiting_verification';
    SQL
  end

  def down
    # Note: Removing enum values is complex in PostgreSQL
    # You might need to create a new type and change the column
    puts "Warning: Enum value removal not implemented"
  end
end