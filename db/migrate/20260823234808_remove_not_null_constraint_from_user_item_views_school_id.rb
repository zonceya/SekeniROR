# db/migrate/YYYYMMDDHHMMSS_remove_not_null_constraint_from_user_item_views_school_id.rb

class RemoveNotNullConstraintFromUserItemViewsSchoolId < ActiveRecord::Migration[7.0] # or your Rails version
  def change
    # ✅ Remove NOT NULL constraint from school_id column
    change_column_null :user_item_views, :school_id, true
  end
end