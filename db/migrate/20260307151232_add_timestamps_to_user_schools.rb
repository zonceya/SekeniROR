# db/migrate/20260307_add_timestamps_to_user_schools.rb
class AddTimestampsToUserSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :user_schools, :updated_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
    
    # Backfill updated_at with created_at for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE user_schools 
          SET updated_at = created_at 
          WHERE updated_at IS NULL
        SQL
      end
    end
  end
end