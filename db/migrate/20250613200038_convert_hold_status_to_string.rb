class ConvertHoldStatusToString < ActiveRecord::Migration[8.0]
  def change
    change_column :holds, :status, :string, default: 'awaiting_payment', null: false
  end
end
