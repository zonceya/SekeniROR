# lib/check_notification_schema.rb
puts "Notification table schema:"
Notification.columns.each do |column|
  puts "  #{column.name}: #{column.type}"
end