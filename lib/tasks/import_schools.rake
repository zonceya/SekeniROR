# lib/tasks/import_schools.rake
require 'csv'
require 'roo'

namespace :import do
  desc "Import schools from Excel file into staging table"
  task :schools_from_excel, [:file_path, :sheet_name] => :environment do |t, args|
    file_path = args[:file_path] || 'data/WesternCapeSchools.xlsx'
    sheet_name = args[:sheet_name] || 'WC'
    
    unless File.exist?(file_path)
      puts "❌ File not found: #{file_path}"
      exit
    end
    
    puts "📂 Reading Excel file: #{file_path}"
    puts "📋 Sheet: #{sheet_name}"
    
    # Open the Excel file
    xlsx = Roo::Excelx.new(file_path)
    xlsx.sheet(sheet_name)
    
    count = 0
    errors = 0
    
    # Get headers from first row
    headers = xlsx.row(1)
    puts "📋 Headers found: #{headers.join(', ')}"
    puts "📋 Number of headers: #{headers.count}"
    
    # Print each header with its index for debugging
    headers.each_with_index do |header, idx|
      puts "  [#{idx}] #{header}"
    end
    
    # Map headers to expected columns - adjust these to match your actual headers
    column_map = {}
    
    # Try to find each column with possible variations
    column_mappings = {
      'NatEmis' => ['NatEmis', 'EMIS', 'EMIS Number', 'NatEmisNo', 'NatEmis_No'],
      'Official_Institution_Name' => ['Official_Institution_Name', 'School Name', 'Institution Name', 'Official Institution Name'],
      'Province' => ['Province', 'ProvinceCode', 'Province CD'],
      'Town_City' => ['Town_City', 'Town', 'City', 'Town/City'],
      'Township_Village' => ['Township_Village', 'Township', 'Village', 'Township/Village'],
      'Suburb' => ['Suburb', 'Suburb/City'],
      'StreetAddress' => ['StreetAddress', 'Street Address', 'Physical Address'],
      'PostalAddress' => ['PostalAddress', 'Postal Address', 'Postal'],
      'Email' => ['Email', 'E-mail', 'Email Address'],
      'Telephone' => ['Telephone', 'Phone', 'Tel', 'Telephone Number'],
      'GIS_Lat' => ['GIS_Lat', 'Latitude', 'GIS Lat', 'Lat'],
      'GIS_Long' => ['GIS_Long', 'Longitude', 'GIS Long', 'Lon', 'Long'],
      'Type_DoE' => ['Type_DoE', 'School Type', 'Type', 'Type DOE'],
      'Learners2025' => ['Learners2025', 'Learners', 'Enrollment', 'Enrolment', 'Total Learners'],
      'Educators2025' => ['Educators2025', 'Educators', 'Teachers', 'Staff', 'Total Educators'],
      'Quintile' => ['Quintile', 'Q', 'School Quintile'],
      'NoFeeSchool' => ['NoFeeSchool', 'No Fee School', 'No Fee', 'Fee Status'],
      'Urban_Rural' => ['Urban_Rural', 'Urban/Rural', 'Location Type'],
      'Status' => ['Status', 'School Status', 'Active/Inactive']
    }
    
    column_mappings.each do |db_field, possible_names|
      found = false
      possible_names.each do |name|
        index = headers.index(name)
        if index
          column_map[db_field] = index
          found = true
          puts "✅ Found '#{db_field}' as '#{name}' at index #{index}"
          break
        end
      end
      puts "⚠️ Missing column: #{db_field} (tried: #{possible_names.join(', ')})" unless found
    end
    
    # Check for missing required columns
    required = ['NatEmis', 'Province']
    missing_required = required.select { |col| column_map[col].nil? }
    if missing_required.any?
      puts "❌ Missing required columns: #{missing_required.join(', ')}"
      puts "   Cannot proceed with import"
      exit
    end
    
    # Helper to safely get column value
    def get_value(row, column_map, col)
      return nil unless column_map[col]
      value = row[column_map[col]]
      value&.to_s&.strip
    end
    
    # Process each row (starting from row 2, after headers)
    (2..xlsx.last_row).each do |row_index|
      begin
        row = xlsx.row(row_index)
        next if row.compact.empty?
        
        # Extract data
        nat_emis = get_value(row, column_map, 'NatEmis')
        province_code = get_value(row, column_map, 'Province')
        
        next if province_code.blank? || nat_emis.blank?
        
        # Verify province exists
        province = Province.find_by(code: province_code)
        unless province
          puts "⚠️ Province not found: #{province_code} for EMIS: #{nat_emis}"
          errors += 1
          next
        end
        
        # Create staging record
        SchoolStagingImport.create!(
          nat_emis: nat_emis,
          official_institution_name: get_value(row, column_map, 'Official_Institution_Name'),
          province: province_code,
          town_city: get_value(row, column_map, 'Town_City'),
          township_village: get_value(row, column_map, 'Township_Village'),
          suburb: get_value(row, column_map, 'Suburb'),
          street_address: get_value(row, column_map, 'StreetAddress'),
          postal_address: get_value(row, column_map, 'PostalAddress'),
          email: get_value(row, column_map, 'Email'),
          telephone: get_value(row, column_map, 'Telephone'),
          gis_lat: get_value(row, column_map, 'GIS_Lat'),
          gis_long: get_value(row, column_map, 'GIS_Long'),
          school_type: get_value(row, column_map, 'Type_DoE'),
          learners_count: get_value(row, column_map, 'Learners2025'),
          educators_count: get_value(row, column_map, 'Educators2025'),
          quintile: get_value(row, column_map, 'Quintile'),
          no_fee_school: get_value(row, column_map, 'NoFeeSchool'),
          urban_rural: get_value(row, column_map, 'Urban_Rural'),
          status: get_value(row, column_map, 'Status'),
          processed_status: 'pending'
        )
        
        count += 1
        print "." if count % 10 == 0
        print count if count % 100 == 0
        
      rescue => e
        errors += 1
        puts "\n❌ Error on row #{row_index}: #{e.message}"
        if errors <= 5
          puts "   Row data: #{row.inspect}"
        end
      end
    end
    
    puts "\n\n✅ Import complete!"
    puts "   📊 Records imported: #{count}"
    puts "   ❌ Errors: #{errors}"
    puts "   📈 Total in staging: #{SchoolStagingImport.count}"
  end
  
  desc "Extract distinct localities for review"
  task :extract_localities, [:output_file] => :environment do |t, args|
    output_file = args[:output_file] || 'data/distinct_localities_for_review.csv'
    
    FileUtils.mkdir_p('data')
    
    puts "📊 Extracting distinct localities from staging table..."
    
    results = {}
    
    SchoolStagingImport.where(processed_status: 'pending').find_each do |record|
      locality = record.resolve_locality
      province = record.province
      key = "#{province}|#{locality}"
      
      results[key] ||= { 
        province: province, 
        locality: locality || "UNALLOCATED", 
        count: 0,
        sample_emis: record.nat_emis
      }
      results[key][:count] += 1
    end
    
    sorted = results.values.sort_by { |r| [r[:province], -r[:count]] }
    
    CSV.open(output_file, "w") do |csv|
      csv << ["province", "raw_locality", "school_count", "sample_emis", "normalized_suggestion", "reviewer_decision"]
      
      sorted.each do |r|
        suggestion = r[:locality].to_s.titleize
        suggestion = suggestion.gsub(/ Village$/, '') if suggestion.ends_with?(' Village')
        
        csv << [r[:province], r[:locality], r[:count], r[:sample_emis], suggestion, ""]
      end
    end
    
    puts "✅ Extracted #{sorted.count} distinct localities"
    puts "📁 Output file: #{output_file}"
  end
  
  desc "Import reviewed towns from CSV"
  task :import_towns, [:file_path] => :environment do |t, args|
    file_path = args[:file_path] || 'data/wc_localities_review.csv'
    
    unless File.exist?(file_path)
      puts "❌ File not found: #{file_path}"
      exit
    end
    
    puts "🏙️ Importing towns from: #{file_path}"
    
    count = 0
    errors = 0
    skipped = 0
    
    CSV.foreach(file_path, headers: true) do |row|
      if row['reviewer_decision'].blank?
        skipped += 1
        next
      end
      
      province = Province.find_by(code: row['province'])
      unless province
        puts "⚠️ Province not found: #{row['province']}"
        errors += 1
        next
      end
      
      town_name = row['reviewer_decision'].strip
      
      if town_name == "Unallocated"
        skipped += 1
        next
      end
      
      begin
        Town.find_or_create_by!(name: town_name, province_id: province.id)
        count += 1
        print "." if count % 10 == 0
      rescue => e
        errors += 1
        puts "\n❌ Error creating town '#{town_name}': #{e.message}"
      end
    end
    
    puts "\n\n✅ Town import complete!"
    puts "   🏙️ Towns created: #{count}"
    puts "   ⏭️ Skipped (Unallocated or blank): #{skipped}"
    puts "   ❌ Errors: #{errors}"
    puts "   📊 Total towns: #{Town.count}"
    
    # Create Unallocated towns for each province
    puts "\n🏙️ Creating 'Unallocated' towns for each province..."
    Province.all.each do |province|
      Town.find_or_create_by(name: "Unallocated", province_id: province.id)
    end
    puts "✅ Done"
  end
  
  desc "Link staging records to towns and create schools"
  task :link_schools_to_towns => :environment do
    puts "🏫 Linking schools to towns..."
    
    processed = 0
    errors = 0
    unallocated_count = 0
    
    SchoolStagingImport.where(processed_status: 'pending').find_each do |record|
      begin
        province = Province.find_by(code: record.province)
        next unless province
        
        locality_raw = record.resolve_locality
        town_name = locality_raw.present? ? locality_raw.titleize : "Unallocated"
        
        if town_name == "99" || town_name.blank?
          town_name = "Unallocated"
          unallocated_count += 1
        end
        
        town = Town.find_or_create_by(name: town_name, province_id: province.id)
        
        location = Location.find_or_create_by(
          province: province.name,
          country: "South Africa",
          town_id: town.id
        )
        
        school = School.find_or_initialize_by(emis: record.nat_emis)
        school.assign_attributes(
          name: record.official_institution_name,
          location_id: location.id,
          province_id: province.id,
          school_type: record.school_type
        )
        school.save!
        
        record.update!(
          processed_status: 'completed',
          resolved_province_id: province.id,
          resolved_town_id: town.id,
          resolved_school_id: school.id,
          resolved_locality_raw: locality_raw || "Unallocated"
        )
        
        processed += 1
        print "." if processed % 10 == 0
        print processed if processed % 100 == 0
        
      rescue => e
        errors += 1
        record.update!(
          processed_status: 'failed',
          error_message: e.message
        )
        puts "\n❌ Error processing EMIS #{record.nat_emis}: #{e.message}"
      end
    end
    
    puts "\n\n✅ Processing complete!"
    puts "   🏫 Schools processed: #{processed}"
    puts "   📌 Unallocated schools: #{unallocated_count}"
    puts "   ❌ Errors: #{errors}"
    puts "   📊 Total schools: #{School.count}"
  end
end