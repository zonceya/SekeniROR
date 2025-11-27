class AddAdminNotesToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :admin_notes, :text
  end
end
