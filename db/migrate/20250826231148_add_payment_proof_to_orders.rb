class AddPaymentProofToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :payment_proof, :text
    add_column :orders, :proof_notes, :text
  end
end
