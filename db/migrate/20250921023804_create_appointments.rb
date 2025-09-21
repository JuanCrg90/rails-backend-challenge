class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :status, default: 0, null: false
      t.datetime :canceled_at
      t.timestamps
    end

    # Performance indexes
    add_index :appointments, [ :provider_id, :starts_at ]
    add_index :appointments, [ :provider_id, :starts_at, :ends_at ]
    add_index :appointments, [ :client_id, :starts_at ]

    # Ensure appointments don't overlap for same provider
    add_check_constraint :appointments, "starts_at < ends_at", name: "chk_appointments_time_order"
  end
end
