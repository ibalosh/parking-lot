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

ActiveRecord::Schema[8.0].define(version: 2025_10_11_134442) do
  create_table "currencies", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "symbol", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "parking_lot_facilities", force: :cascade do |t|
    t.string "name"
    t.integer "spaces_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "spaces_count >= 0", name: "spaces_count_positive"
  end

  create_table "prices", force: :cascade do |t|
    t.integer "parking_lot_facility_id", null: false
    t.decimal "price_per_hour", precision: 10, scale: 2, null: false
    t.integer "currency_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_prices_on_currency_id"
    t.index ["parking_lot_facility_id"], name: "index_prices_on_parking_lot_facility_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "barcode", null: false
    t.integer "parking_lot_facility_id", null: false
    t.datetime "issued_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price_id", null: false
    t.index ["barcode"], name: "index_tickets_on_barcode", unique: true
    t.index ["parking_lot_facility_id"], name: "index_tickets_on_parking_lot_facility_id"
    t.index ["price_id"], name: "index_tickets_on_price_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "prices", "currencies"
  add_foreign_key "prices", "parking_lot_facilities"
  add_foreign_key "tickets", "parking_lot_facilities"
  add_foreign_key "tickets", "prices"
end
