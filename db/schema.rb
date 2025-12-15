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

ActiveRecord::Schema[8.1].define(version: 2025_12_06_233214) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bills", force: :cascade do |t|
    t.integer "amount", null: false
    t.boolean "auto_charge", default: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "period"
    t.string "status", default: "pending"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_bills_on_unit_id"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "viewer", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "note", comment: "Note for approval/rejection tracking"
    t.string "org_type", default: "community", null: false
    t.string "rut", null: false
    t.string "slug"
    t.string "status", default: "pending", null: false
    t.string "tbk_child_commerce_code", comment: "Provided by Transbank per organization"
    t.string "transbank_id", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug"
    t.index ["transbank_id"], name: "index_organizations_on_transbank_id", unique: true
  end

  create_table "payment_methods", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "card_last_4"
    t.string "card_type"
    t.datetime "created_at", null: false
    t.string "tbk_token", null: false
    t.string "tbk_username", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "tbk_token"], name: "index_payment_methods_on_user_id_and_tbk_token", unique: true
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "bill_id", null: false
    t.string "child_buy_order", null: false
    t.datetime "created_at", null: false
    t.jsonb "gateway_payload"
    t.bigint "organization_id", null: false
    t.string "parent_buy_order", null: false
    t.bigint "payer_user_id", null: false
    t.bigint "payment_method_id"
    t.string "period", null: false
    t.integer "response_code"
    t.string "status", default: "initiated", null: false
    t.string "tbk_auth_code"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_payments_on_bill_id"
    t.index ["child_buy_order"], name: "index_payments_on_child_buy_order", unique: true
    t.index ["organization_id"], name: "index_payments_on_organization_id"
    t.index ["parent_buy_order"], name: "index_payments_on_parent_buy_order", unique: true
    t.index ["payer_user_id"], name: "index_payments_on_payer_user_id"
    t.index ["payment_method_id"], name: "index_payments_on_payment_method_id"
    t.index ["unit_id"], name: "index_payments_on_unit_id"
  end

  create_table "unit_user_assignments", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.date "ends_on"
    t.date "starts_on", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["unit_id", "user_id", "starts_on"], name: "idx_unit_user_assign_hist"
    t.index ["unit_id"], name: "index_unit_user_assignments_on_unit_id"
    t.index ["user_id"], name: "index_unit_user_assignments_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "number", null: false
    t.bigint "organization_id", null: false
    t.float "proration"
    t.string "tower"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "number", "tower"], name: "idx_units_unique_key", unique: true
    t.index ["organization_id"], name: "index_units_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.text "note", comment: "Note for approval/rejection tracking"
    t.bigint "organization_id"
    t.string "password_digest", null: false
    t.string "role", default: "resident", null: false
    t.text "signup_note", comment: "Note provided by user during signup"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "bills", "units"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "payments", "bills"
  add_foreign_key "payments", "organizations"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payments", "units"
  add_foreign_key "payments", "users", column: "payer_user_id"
  add_foreign_key "unit_user_assignments", "units"
  add_foreign_key "unit_user_assignments", "users"
  add_foreign_key "units", "organizations"
  add_foreign_key "users", "organizations"
end
