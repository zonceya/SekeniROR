namespace :images do
  desc "Migrate cover_photo URLs to Active Storage"
  task migrate_from_cdn: :environment do
    puts "Starting image migration..."
    
    Item.where.not(cover_photo: nil).find_each.with_index do |item, index|
      next if item.cover_photo.blank?
      
      print "Processing item #{index + 1}: #{item.name}... "
      
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
        
        puts "✅ Success"
        
      rescue OpenURI::HTTPError => e
        puts "❌ HTTP Error: #{e.message}"
      rescue => e
        puts "❌ Failed: #{e.message}"
      end
    end
    
    puts "\n✨ Migration complete!"
  end
end