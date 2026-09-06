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

ActiveRecord::Schema[8.1].define(version: 2026_09_06_094651) do
  create_table "accounts", charset: "utf8mb3", force: :cascade do |t|
    t.string "account_number"
    t.string "account_scope", default: "personal", null: false
    t.decimal "balance", precision: 10
    t.bigint "bank_id", null: false
    t.datetime "created_at", null: false
    t.string "decimal"
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_scope"], name: "index_accounts_on_account_scope"
    t.index ["bank_id"], name: "index_accounts_on_bank_id"
    t.index ["organization_id"], name: "index_accounts_on_organization_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "active_storage_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "banks", charset: "utf8mb3", force: :cascade do |t|
    t.string "bank"
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "organization_memberships", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_organization_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "public_id"
    t.datetime "updated_at", null: false
    t.index ["public_id"], name: "index_organizations_on_public_id", unique: true
  end

  create_table "transactions", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "account_id"
    t.integer "amount"
    t.string "card_number"
    t.string "category"
    t.datetime "created_at", null: false
    t.date "date"
    t.bigint "organization_id", null: false
    t.string "payment_method"
    t.string "transaction_scope", default: "organization", null: false
    t.string "transaction_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["organization_id"], name: "index_transactions_on_organization_id"
    t.index ["transaction_scope"], name: "index_transactions_on_transaction_scope"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "password_digest"
    t.string "public_id"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["public_id"], name: "index_users_on_public_id", unique: true
  end

  add_foreign_key "accounts", "banks"
  add_foreign_key "accounts", "organizations"
  add_foreign_key "accounts", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "organizations"
  add_foreign_key "transactions", "users"
  add_foreign_key "users", "organizations"
end
