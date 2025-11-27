class AddBankToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :bank, :string
  end
end
