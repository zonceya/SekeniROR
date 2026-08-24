# db/seeds/school_logos.rb
# Run with: rails db:seed --trace or RAILS_ENV=staging rails db:seed

puts "🏫 Adding School Logos..."
puts "=" * 60

CDN_BASE = "https://cdn.skoolswap.co.za"
LOGOS_PATH = "schools_demo/school_logo"

# All schools with their logo files - using actual database names
school_logos = {
  # === DEMO SCHOOLS ===
  "Ashridge Primary (Demo)" => "ashridge_primary_logo.webp",
  "Ironwood College (Demo)" => "Ironwood_College_logo.webp",
  "Mountain Ridge High (Demo)" => "Mount_High_logo.webp",
  "Riverside College (Demo)" => "riveside_college_logo.webp",
  "St. Elara's College (Demo)" => "St._Elaras_College_log.webp",
  "Ubuntu Community School (Demo)" => "ubuntu_school_logo.webp",
  "Willowcrest (Demo)" => "willowcrest_logo.webp",

  # === REAL SCHOOLS (Updated) ===
  "PRETORIA HIGH SCHOOL FOR GIRLS" => "Pretoria_High_School_for_Girls.webp",
  "KING EDWARD VII SCHOOL" => "King_Edward_VII_School.webp",
  "ST STITHIANS COLLEGE" => "St_Stithians_College.webp",
  "BRYANDALE PRIMARY SCHOOL" => "Bryandale_Primary_School.webp",
  "RONDEBOSCH BOYS' HIGH SCHOOL" => "Rondebosch_Boys_High_School.webp",
  "WYNBERG GIRLS' HIGH SCHOOL" => "Wynberg_Girls_High_School.webp",
  "CLAREMONT PRIMARY SCHOOL" => "Claremont_Primary_School.webp",
  "HILTON COLLEGE" => "Hilton_College.webp",
  "DURBAN GIRLS' COLLEGE" => "Durban_Girls_College.webp",
  "CLIFTON SCHOOL" => "Clifton_School.webp",
  "HOËRSKOOL GOUDRIF" => "HS_GOUDRIF.jpeg",
  "LAERSKOOL ALBERTYN" => "LS_ALBERTYN.jpg",
  "LAERSKOOL BEKKER" => "LS-Bekker.png",
  "LAERSKOOL DENNESIG" => "LAERSKOOL_DENNESIG.jpeg",
  "LAERSKOOL INNES" => "LS_INNES.jpg",
  "LAERSKOOL LOUW GELDENHUYS" => "LS_LOUW_GELDENHUYS.jpg",
  "LAERSKOOL PROTEARIF" => "LAERSKOOL_PROTEARIF.jpg",
  "LAERSKOOL RANDFONTEIN" => "LS-Randfontein-1.jpg",
  "BORDEAUX PRIMARY SCHOOL" => "BORDEAUX_PRIMARY_SCHOOL.jpeg",
  "CRAWFORD INTERNATIONAL BEDFORDVIEW" => "CRAWFORD_INTERNATIONAL_BEDFORDVIEW.jpg",
  "CRYSTAL PARK PRIMARY SCHOOL" => "CRYSTAL_PARK_PRIMARY_SCHOOL.jpg",
  "DAINFERN COLLEGE" => "Dainfern_College.jpg",
  "DALE COLLEGE" => "Dale_College.png",
  "DUNVEGAN PRIMARY SCHOOL" => "DUNVEGAN_PRIMARY_SCHOOL.jpeg",
  "GLENANDA PRIMARY SCHOOL" => "GLENANDA_PRIMARY_SCHOOL.png",
  "HYDE PARK HIGH SCHOOL" => "HYDE_PARK_HS.jpg",
  "JAPARI SCHOOL" => "Japari_School.png",
  "KABEGA PRIMARY SCHOOL" => "Kabega_Primary_School.png",
  "MOUNT PLEASANT PRIMARY SCHOOL" => "MOUNT_PLEASANT_PS.jpg",
  "PRETORIA CENTRAL HIGH SCHOOL" => "PRETORIA_CENTRAL_HS.jpeg",

  # === FOUND ON STAGING (Updated) ===
  "BISHOPS" => "Bishops_Diocesan_College.webp",
  "LAERSKOOL SETLAARSPARK" => "LS_SETTLAARSPARK.jpg",
  "GREY BOYS HIGH SCHOOL" => "Grey_High_School.webp",
  "HOERSKOOL WARMBAD" => "HS_WARMBAD.jpeg",
  "LAERSKOOL WARMBAD" => "HS_WARMBAD.jpeg",
  "BLANCO LAERSKOOL" => "Laerskool_Blanco.jpg",
  "LAERSKOOL DR HAVINGA" => "LAERSKOOL_DR_HAVINGA.png",
  "LOSBERG PRIMARY SCHOOL" => "LAERSKOOL_LOSBERG.jpg",
  "THE KING'S SCHOOL MULDERSDRIFT" => "LAERSKOOL_MULDERSDRIFT.jpg",
  "ALBERVIEW PRIMARY SCHOOL" => "Alberview.jpeg",
  "BRAKPAN HIGH SCHOOL" => "BRAKPAN.jpg",
  "BREIDBACH FULL SERVICE SCHOOL" => "BREIDBACH.jpg",

  # === EC SCHOOLS ===
  "AARON GQADU PRIMARY SCHOOL" => "AARON_GQADU_PRIMARY_SCHOOL.jpg",
  "ABERDEEN SECONDARY SCHOOL" => "ABERDEEN_SECONDARY_SCHOOL.jpg",
  "ABRAHAM LEVY PRIMARY" => "ABRAHAM_LEVY_PRIMARY.jpg",
  "ADELAIDE GYMNASIUM" => "ADELAIDE_GYMNASIUM_TECHNICAL_SCHOOL.jpg",
  "ADELAIDE PRIMARY SCHOOL" => "ADELAIDE_PRIMARY_SCHOOL.jpg",
  "AEROVILLE SECONDARY SCHOOL" => "AEROVILLE_SECONDARY_SCHOOL.jpg",
  "ALAZHAR PRIMARY SCHOOL" => "ALAZHAR_PRIMARY_SCHOOL.png",
  "ALEXANDER ROAD HIGH SCHOOL" => "ALEXANDER_ROAD_HIGH_SCHOOL.png",
  "ALEXANDRIA FULL SERVICE SCHOOL" => "ALEXANDRIA_FULL_SERVICE_SCHOOL.png",
  "ALEXANDRIA HIGH SCHOOL" => "ALEXANDRIA_HIGH_SCHOOL.jpg",
  "ALPHA PRIMARY SCHOOL" => "ALPHA_PRIMARY_SCHOOL.jpg",
  "ALTONA PRIMARY SCHOOL" => "ALTONA_PRIMARY_SCHOOL.png",
  "ANDREW RABIE HIGH SCHOOL" => "ANDREW_RABIE_HIGH_SCHOOL.avif",
  "ANKERVAS PRIMARY SCHOOL" => "ANKERVAS_PRIMARY_SCHOOL.jpg",
  "ARCADIA PRIMARY SCHOOL" => "ARCADIAPRIMARY.jpg",
  "ARCADIA SENIOR SECONDARY SCHOOL" => "ARCADIA_SENIOR_SECONDARY_SCHOOL.jpeg",
  "ARCHIE MBOLEKWA JUNIOR PRIMARY SCHOOL" => "ARCHIE_MBOLEKWA_JUNIOR_PRIMARY_SCHOOL.jpg",
  "ASHERVILLE PUBLIC SCHOOL" => "ASHERVILLE_PUBLIC_SCHOOL.jpg",
  "ASTRA PRIMARY SCHOOL" => "ASTRA_PRIMARY_SCHOOL.jpg",

  # === EC SCHOOLS (B) ===
  "B J MNYANDA PRIMARY SCHOOL" => "B_J_MNYANDA_PRIMARY_SCHOOL.jpg",
  "BATHURST PRIMARY SCHOOL" => "BATHURST_PRIMARY_SCHOOL.png",
  "BAYVIEW PRIMARY SCHOOL" => "BAYVIEW_PRIMARY_SCHOOL.jpg",
  "BEDFORD JUNIOR SECONDARY SCHOOL" => "BEDFORD_JUNIOR_SECONDARY_SCHOOL.png",
  "BELMONT FARM SCHOOL" => "BELMONT_FARM_SCHOOL.jpg",
  "BEN SINUKA PRIMARY SCHOOL" => "BEN_SINUKA_PRIMARY_SCHOOL.jpg",
  "BETHELSDORP COMPREHENSIVE SCHOOL" => "BETHELSDORP_COMPREHENSIVE_SCHOOL.jpg",
  "BLESSING CHRISTIAN LEARNING ACADEMY" => "BLESSING_CHRISTIAN_LEARNING_ACADEMY_INTERNATIONAL_AND_BOARDING_COLLEGE.jfif",

  # === EC SCHOOLS (C-Z) ===
  "DALE COLLEGE BOYS' PRIMARY SCHOOL" => "Dale.png",
  "DALE JUNIOR SECONDARY SCHOOL" => "Dale.png",
  "HAPPY HOME ACADEMY" => "HAPPY_HOME_ACADEMY.png",
  "KINGS AND QUEENS" => "QUEENS_COLLEGE_BOYS_HIGH_SCHOOL.avif",
  "KINGSLEY PRIVATE SCHOOL" => "KINGS_KIDZ_SCHOOL.jpg",
  "NEWTOWN HIGH SCHOOL" => "NEWTOWN_HIGH_SCHOOL.jpg",
  "PROTEA HEIGHTS ACADEMY" => "PROTEA_HEIGHTS_ACADEMY.png",
  "SELBORNE COLLEGE" => "SELBORNE_COLLEGE.jpg",
  "SIPHO CAMAGU HIGH SCHOOL" => "SIPHO_CAMAGU_HIGH_SCHOOL.jpg",
  "ST. ANDREW'S COLLEGE" => "ST_ANDREWS_COLLGE.png"
}

puts "📦 Adding #{school_logos.count} school logos..."
updated = 0
not_found = []
needs_fix = []

school_logos.each do |school_name, logo_file|
  # Try exact match first
  school = School.find_by(name: school_name)
  
  # If not found, try case-insensitive match
  if school.nil?
    school = School.find_by("LOWER(name) = ?", school_name.downcase)
  end
  
  if school
    logo_url = "#{CDN_BASE}/#{LOGOS_PATH}/#{logo_file}"
    school.update!(logo_url: logo_url)
    puts "✅ #{school_name} → #{logo_file}"
    updated += 1
  else
    puts "❌ #{school_name} not found"
    not_found << school_name
  end
end

puts ""
puts "=" * 60
puts "📊 SUMMARY"
puts "=" * 60
puts "  ✅ Updated: #{updated}/#{school_logos.count}"
puts "  ❌ Not found: #{not_found.count}"
puts "  📋 Total schools with logos: #{School.where.not(logo_url: [nil, '']).count}/#{School.count}"

if not_found.any?
  puts ""
  puts "🔍 Schools not found in database:"
  not_found.each { |name| puts "  - #{name}" }
end

# Show schools without logos
puts ""
puts "🔍 Schools without logos:"
schools_without_logos = School.where(logo_url: [nil, '']).limit(20)
if schools_without_logos.any?
  puts "  ⚠️ Found #{School.where(logo_url: [nil, '']).count} schools without logos"
  puts "  First 20:"
  schools_without_logos.pluck(:name).each { |name| puts "    - #{name}" }
else
  puts "  ✅ All schools have logos!"
end