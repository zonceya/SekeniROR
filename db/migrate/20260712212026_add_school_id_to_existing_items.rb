# db/migrate/20260712212026_add_school_id_to_existing_items.rb

class AddSchoolIdToExistingItems < ActiveRecord::Migration[8.0]
  def up
    say "🏫 Backfilling school_id for existing items..."
    
    # First, get all schools
    schools = execute("SELECT id, name FROM schools").to_a
    school_mappings = schools.map { |s| [s["name"].downcase.strip, s["id"]] }.to_h
    
    say "Found #{school_mappings.size} schools"
    
    # Find items without school_id
    items_without_school = execute("SELECT id, name, description FROM items WHERE school_id IS NULL").to_a
    
    say "Found #{items_without_school.size} items without school_id"
    
    updated_count = 0
    
    items_without_school.each do |item|
      description = item["description"] || ""
      name = item["name"] || ""
      text_to_search = [description, name].join(" ").downcase
      
      # Try to find a school match
      matched_school_id = nil
      matched_school_name = nil
      
      school_mappings.each do |school_name, school_id|
        if text_to_search.include?(school_name)
          matched_school_id = school_id
          matched_school_name = school_name
          break
        end
      end
      
      # If no match, try pattern matching
      if matched_school_id.nil?
        patterns = [
          /([a-z][a-z\s]+high|school|academy|college|primary|secondary)/,
          /(?:at|from|for)\s+([a-z][a-z\s]+?(?:high|school|academy|college))/
        ]
        
        patterns.each do |pattern|
          match = text_to_search.match(pattern)
          if match && match[1]
            extracted = match[1].strip
            school_mappings.each do |school_name, school_id|
              if extracted.include?(school_name) || school_name.include?(extracted)
                matched_school_id = school_id
                matched_school_name = school_name
                break
              end
            end
            break if matched_school_id
          end
        end
      end
      
      # Update the item if we found a match
      if matched_school_id
        execute("UPDATE items SET school_id = #{matched_school_id} WHERE id = '#{item["id"]}'")
        updated_count += 1
        say "✅ Updated: #{item["name"]} → #{matched_school_name}"
      end
    end
    
    say "=" * 50
    say "✅ Updated #{updated_count} items with school_id"
    
    remaining = execute("SELECT COUNT(*) FROM items WHERE school_id IS NULL").first["count"]
    say "⏭️ #{remaining} items still have no school_id"
  end

  def down
    # Rollback - remove school_id for items that were updated
    # execute("UPDATE items SET school_id = NULL WHERE school_id IN (SELECT id FROM schools)")
    say "⚠️ This migration is not reversible"
  end
end