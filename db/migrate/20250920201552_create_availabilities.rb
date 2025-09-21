# db/migrate/20250920120000_create_availabilities.rb
class CreateAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :availabilities do |t|
      t.references :provider, null: false, foreign_key: true

      t.string  :remote_id, null: false

      # 0..6 (Sunday=0)
      t.integer :day_of_week, null: false

      # Minutes since midnight (0..1439)
      t.integer :starts_at_minute, null: false
      t.integer :ends_at_minute,   null: false

      t.string :source, null: false, default: "calendly"

      t.timestamps
    end

    add_index :availabilities, [ :provider_id, :day_of_week, :starts_at_minute ]
    add_index :availabilities, [ :provider_id, :remote_id, :source ], unique: true

    # Defensive DB checks (SQLite supports CHECK)
    add_check_constraint :availabilities, "day_of_week BETWEEN 0 AND 6", name: "chk_availabilities_dow"
    add_check_constraint :availabilities, "starts_at_minute BETWEEN 0 AND 1439", name: "chk_availabilities_start"
    add_check_constraint :availabilities, "ends_at_minute BETWEEN 1 AND 1440", name: "chk_availabilities_end"
    add_check_constraint :availabilities, "starts_at_minute < ends_at_minute", name: "chk_availabilities_order"
  end
end
