class AddDurationMsToApplicationLog < ActiveRecord::Migration[8.0]
  def change
    add_column :application_logs, :duration_ms, :integer
  end
end
