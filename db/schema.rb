# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_21_023804) do
  create_table "appointments", force: :cascade do |t|
    t.integer "provider_id", null: false
    t.integer "client_id", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "status", default: 0, null: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "starts_at"], name: "index_appointments_on_client_id_and_starts_at"
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["provider_id", "starts_at", "ends_at"], name: "index_appointments_on_provider_id_and_starts_at_and_ends_at"
    t.index ["provider_id", "starts_at"], name: "index_appointments_on_provider_id_and_starts_at"
    t.index ["provider_id"], name: "index_appointments_on_provider_id"
    t.check_constraint "starts_at < ends_at", name: "chk_appointments_time_order"
  end

  create_table "availabilities", force: :cascade do |t|
    t.integer "provider_id", null: false
    t.string "remote_id", null: false
    t.integer "day_of_week", null: false
    t.integer "starts_at_minute", null: false
    t.integer "ends_at_minute", null: false
    t.string "source", default: "calendly", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "day_of_week", "starts_at_minute"], name: "idx_on_provider_id_day_of_week_starts_at_minute_3212a292cc"
    t.index ["provider_id", "remote_id", "source"], name: "index_availabilities_on_provider_id_and_remote_id_and_source", unique: true
    t.index ["provider_id"], name: "index_availabilities_on_provider_id"
    t.check_constraint "day_of_week BETWEEN 0 AND 6", name: "chk_availabilities_dow"
    t.check_constraint "ends_at_minute BETWEEN 1 AND 1440", name: "chk_availabilities_end"
    t.check_constraint "starts_at_minute < ends_at_minute", name: "chk_availabilities_order"
    t.check_constraint "starts_at_minute BETWEEN 0 AND 1439", name: "chk_availabilities_start"
  end

  create_table "clients", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "providers", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "appointments", "clients"
  add_foreign_key "appointments", "providers"
  add_foreign_key "availabilities", "providers"
end
