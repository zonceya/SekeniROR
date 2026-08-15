# db/migrate/20260806202213_add_demo_to_school_names.rb
class AddDemoToSchoolNames < ActiveRecord::Migration[8.0]
  def change
    # 1. Add columns to items
    add_column :items, :is_system, :boolean, default: false, null: false
    add_column :items, :display_order, :integer, default: 0
    
    # 2. Add column to schools
    add_column :schools, :is_system, :boolean, default: false, null: false
    
    # 3. Add index
    add_index :items, [:is_system, :display_order], name: 'index_items_on_system_and_order'
    
    # 4. Mark demo schools as system and add (Demo) suffix
    reversible do |dir|
      dir.up do
        demo_school_ids = [14, 15, 16, 17, 18, 19, 20, 21, 22]
        
        # Mark schools as system
        School.where(id: demo_school_ids).update_all(is_system: true)
        
        # Mark items from these schools as system
        Item.where(school_id: demo_school_ids).update_all(is_system: true)
        
        # Set display order for system items
        Item.where(is_system: true).order(:created_at).each_with_index do |item, index|
          item.update!(display_order: index)
        end
        
        # Clean up and add (Demo) suffix to demo schools
        clean_names = {
          14 => "Mountain Ridge High",
          15 => "Riverside College",
          16 => "Ironwood College",
          17 => "St. Elara's College",
          18 => "Ashridge Primary",
          19 => "Mountain Ridge High",
          20 => "Riverside College",
          21 => "Ubuntu Community School",
          22 => "Willowcrest"
        }
        
        clean_names.each do |id, name|
          school = School.find_by(id: id)
          if school && school.name != name
            school.update!(name: name)
          end
        end
        
        # Add (Demo) suffix
        School.where(id: demo_school_ids).each do |school|
          unless school.name.include?("(Demo)")
            school.update!(name: "#{school.name} (Demo)")
          end
        end
        
        puts "✅ Migration complete!"
        puts "   - #{Item.where(is_system: true).count} system items"
        puts "   - #{School.where(is_system: true).count} system schools"
      end
      
      dir.down do
        demo_school_ids = [14, 15, 16, 17, 18, 19, 20, 21, 22]
        
        # Remove (Demo) suffix
        School.where(id: demo_school_ids).each do |school|
          if school.name.include?(" (Demo)")
            school.update!(name: school.name.gsub(" (Demo)", ""))
          end
        end
      end
    end
  end
end