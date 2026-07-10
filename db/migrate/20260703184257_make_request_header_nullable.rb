# db/migrate/20260703_make_request_header_nullable.rb
class MakeRequestHeaderNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :application_logs, :request_header, true
  end
end