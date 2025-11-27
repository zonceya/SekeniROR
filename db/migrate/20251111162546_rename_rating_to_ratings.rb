class RenameRatingToRatings < ActiveRecord::Migration[8.0]
   def change
    rename_table :rating, :ratings
  end
end

