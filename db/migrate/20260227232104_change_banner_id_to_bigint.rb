# db/migrate/20260227232104_change_banner_id_to_bigint.rb
class ChangeBannerIdToBigint < ActiveRecord::Migration[6.0]
  def up
    # First, remove the existing primary key constraint
    execute <<-SQL
      ALTER TABLE banners DROP CONSTRAINT banners_pkey CASCADE
    SQL
    
    # Rename the old uuid column
    rename_column :banners, :id, :uuid_id
    
    # Add new bigint column as primary key
    add_column :banners, :id, :bigserial, null: false
    
    # Set it as primary key
    execute <<-SQL
      ALTER TABLE banners ADD PRIMARY KEY (id)
    SQL
    
    # Copy data - generate new bigint IDs for existing records
    # The bigserial will auto-assign values
    
    # Update attachments to use the new ID
    execute <<-SQL
      UPDATE active_storage_attachments 
      SET record_id = banners.id 
      FROM banners 
      WHERE active_storage_attachments.record_type = 'Banner' 
        AND active_storage_attachments.record_id::text = banners.uuid_id::text
    SQL
    
    # Remove the old uuid column
    remove_column :banners, :uuid_id
    
    # Reset the sequence to start after the max ID
    execute <<-SQL
      SELECT setval('banners_id_seq', (SELECT MAX(id) FROM banners))
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end