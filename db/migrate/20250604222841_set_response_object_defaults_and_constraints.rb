class SetResponseObjectDefaultsAndConstraints < ActiveRecord::Migration[6.1]
  def change
    change_column_null :application_logs, :response_object, false
    change_column_default :application_logs, :response_object, from: nil, to: "{}"
  end
end