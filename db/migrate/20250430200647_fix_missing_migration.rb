class FixMissingMigration < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.bigint :user_id, null: false
      t.string :profile_picture
      t.string :mobile
      t.timestamps
    end

    add_foreign_key :profiles, :users
  end
end
