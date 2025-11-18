# db/migrate/20251113211000_fix_ratings_system_structure.rb
class FixRatingsSystemStructure < ActiveRecord::Migration[8.0]
  def change
    # Drop the old ratings table (it's the shop summary table with wrong name)
    drop_table :ratings if table_exists?(:ratings)

    # Create the new ratings table for individual ratings
    create_table :ratings do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :rater, null: false, foreign_key: { to_table: :users }
      t.references :rated, null: false, foreign_key: { to_table: :users }
      t.references :shop, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :review
      t.string :rating_type, null: false
      t.timestamps

      t.index [:order_id, :rater_id, :rating_type], unique: true, name: 'unique_rating_per_order_and_type'
    end

    # Ensure shop_ratings table has the right structure
    if table_exists?(:shop_ratings)
      # Add missing columns to shop_ratings
      add_column :shop_ratings, :average_rating, :decimal, precision: 3, scale: 2, default: 0.00 unless column_exists?(:shop_ratings, :average_rating)
      add_column :shop_ratings, :total_ratings, :integer, default: 0 unless column_exists?(:shop_ratings, :total_ratings)
      add_column :shop_ratings, :rating_1, :integer, default: 0 unless column_exists?(:shop_ratings, :rating_1)
      add_column :shop_ratings, :rating_2, :integer, default: 0 unless column_exists?(:shop_ratings, :rating_2)
      add_column :shop_ratings, :rating_3, :integer, default: 0 unless column_exists?(:shop_ratings, :rating_3)
      add_column :shop_ratings, :rating_4, :integer, default: 0 unless column_exists?(:shop_ratings, :rating_4)
      add_column :shop_ratings, :rating_5, :integer, default: 0 unless column_exists?(:shop_ratings, :rating_5)
      add_column :shop_ratings, :created_at, :datetime unless column_exists?(:shop_ratings, :created_at)
      add_column :shop_ratings, :updated_at, :datetime unless column_exists?(:shop_ratings, :updated_at)
    else
      create_table :shop_ratings do |t|
        t.references :shop, null: false, foreign_key: true
        t.decimal :average_rating, precision: 3, scale: 2, default: 0.00
        t.integer :total_ratings, default: 0
        t.integer :rating_1, default: 0
        t.integer :rating_2, default: 0
        t.integer :rating_3, default: 0
        t.integer :rating_4, default: 0
        t.integer :rating_5, default: 0
        t.timestamps
      end
    end

    # Ensure user_ratings table exists
    unless table_exists?(:user_ratings)
      create_table :user_ratings do |t|
        t.references :user, null: false, foreign_key: true
        t.decimal :average_rating, precision: 3, scale: 2, default: 0.00
        t.integer :total_ratings, default: 0
        t.timestamps
      end
    end
  end
end