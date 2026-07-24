# db/migrate/XXXXXX_create_school_staging_imports.rb
class CreateSchoolStagingImports < ActiveRecord::Migration[8.0]
  def change
    create_table :school_staging_imports do |t|
      # Core identifiers
      t.string  :nat_emis
      t.string  :official_institution_name
      t.string  :province          # e.g. "LP", "MP" — matches provinces.code
      
      # Location fields (priority: Township_Village > Suburb > Town_City)
      t.string  :town_city
      t.string  :township_village
      t.string  :suburb
      
      # Address fields
      t.text    :street_address
      t.text    :postal_address
      
      # Contact
      t.string  :email
      t.string  :telephone
      
      # GIS
      t.string  :gis_lat
      t.string  :gis_long
      
      # School details
      t.string  :school_type
      t.string  :learners_count
      t.string  :educators_count
      t.string  :quintile
      t.string  :no_fee_school
      t.string  :urban_rural
      t.string  :status
      
      # Processing fields
      t.string   :processed_status, default: "pending"
      t.text     :error_message
      t.integer  :resolved_town_id
      t.integer  :resolved_province_id
      t.integer  :resolved_school_id
      t.string   :resolved_locality_raw
      
      t.timestamps
    end

    add_index :school_staging_imports, :nat_emis
    add_index :school_staging_imports, :processed_status
    add_index :school_staging_imports, :province
  end
end
