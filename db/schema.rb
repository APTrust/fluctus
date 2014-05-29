# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140528144435) do

  create_table "bookmarks", force: true do |t|
    t.integer  "user_id",     null: false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  create_table "processed_items", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "etag"
    t.string   "bag_date"
    t.string   "bucket"
    t.string   "user"
    t.string   "institution"
    t.string   "date"
    t.string   "note"
    t.string   "action"
    t.string   "stage"
    t.string   "status"
    t.string   "outcome"
  end

  add_index "processed_items", ["action"], name: "index_processed_items_on_action"
  add_index "processed_items", ["date"], name: "index_processed_items_on_date"
  add_index "processed_items", ["etag", "name"], name: "index_processed_items_on_etag_and_name"
  add_index "processed_items", ["institution"], name: "index_processed_items_on_institution"
  add_index "processed_items", ["stage"], name: "index_processed_items_on_stage"
  add_index "processed_items", ["status"], name: "index_processed_items_on_status"

# Could not dump table "processing_queues" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "roles", force: true do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id"
  add_index "roles_users", ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id"

  create_table "searches", force: true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "usage_samples", force: true do |t|
    t.string   "institution_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                    default: "", null: false
    t.string   "encrypted_password",       default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "phone_number"
    t.string   "institution_pid"
    t.text     "encrypted_api_secret_key"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
