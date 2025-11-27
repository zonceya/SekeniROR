class AddStatusToApplicationLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :application_logs, :status, :integer
  end
end
