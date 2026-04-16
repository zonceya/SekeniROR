class MigrateCoverPhotosToActiveStorage < ActiveRecord::Migration[7.0]
  def up
    Item.where.not(cover_photo: nil).find_each do |item|
      next if item.cover_photo.blank?
      
      begin
        filename = item.cover_photo.split('/').last
        filename = "item_#{item.id}_#{filename}" if filename.blank?
        
        uri = URI.parse(item.cover_photo)
        file = uri.open(read_timeout: 10)
        
        item.images.attach(
          io: file,
          filename: filename,
          content_type: file.content_type || 'image/jpeg'
        )
        
        puts "✅ Migrated image for item #{item.id}: #{item.name}"
        
      rescue OpenURI::HTTPError => e
        puts "❌ HTTP Error for item #{item.id}: #{e.message}"
      rescue => e
        puts "❌ Failed for item #{item.id}: #{e.message}"
      end
    end
  end

  def down
    # Optional: rollback logic
    puts "This migration cannot be rolled back easily"
  end
end