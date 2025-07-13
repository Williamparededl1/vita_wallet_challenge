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

ActiveRecord::Schema[8.0].define(version: 2025_07_13_222650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "transactions", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "sender_address", null: false
    t.string "receiver_address", null: false
    t.decimal "amount", precision: 18, scale: 8, null: false
    t.integer "nonce", null: false
    t.text "raw_transaction_message", null: false
    t.text "signature", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.string "address", null: false
    t.text "public_key_hex", null: false
    t.decimal "balance", precision: 18, scale: 8, default: "0.0", null: false
    t.boolean "is_master", default: false, null: false
    t.integer "incoming_tx_count", default: 0, null: false
    t.integer "outcoming_tx_count", default: 0, null: false
    t.integer "last_nonce", default: -1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_wallets_on_address", unique: true
  end
end
