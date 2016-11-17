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

ActiveRecord::Schema.define(version: 20161031231015) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "connections", force: :cascade do |t|
    t.string  "name"
    t.string  "address"
    t.boolean "ssl"
    t.boolean "active"
    t.string  "side"
  end

  create_table "dictionaries", force: :cascade do |t|
    t.string  "name"
    t.integer "subset_id"
  end

  add_index "dictionaries", ["subset_id"], name: "index_dictionaries_on_subset_id", using: :btree

  create_table "e_lexes", force: :cascade do |t|
    t.string "lex"
  end

  create_table "events", force: :cascade do |t|
    t.string   "event"
    t.string   "response_code"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.float    "response_time"
    t.string   "origin"
    t.string   "recepient"
    t.text     "parameters"
  end

  create_table "g_lexes", force: :cascade do |t|
    t.string "lex"
  end

  create_table "people", force: :cascade do |t|
    t.string   "email",            null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "people", ["email"], name: "index_people_on_email", unique: true, using: :btree

  create_table "r_lexes", force: :cascade do |t|
    t.string "lex"
  end

  create_table "runtimes", force: :cascade do |t|
    t.datetime "date"
    t.string   "from"
    t.string   "to"
    t.string   "message_id"
    t.string   "operator_login"
    t.text     "text"
    t.integer  "status"
    t.string   "session_id"
    t.string   "psap_id"
  end

  create_table "senses", force: :cascade do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.string  "slang"
    t.string  "tlang"
  end

  create_table "settings", force: :cascade do |t|
    t.string  "mode"
    t.integer "sessions_daily"
    t.integer "messages_daily"
    t.string  "session_diration"
    t.integer "psaps_online"
    t.integer "total_calltakers"
  end

  create_table "statuses", force: :cascade do |t|
    t.integer "pool_size"
    t.string  "status"
    t.integer "ramp_up"
    t.integer "refresh_interval"
    t.integer "conv_day"
    t.integer "mess_conv"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "login"
    t.string   "password"
    t.boolean  "online"
    t.string   "psap"
    t.string   "email"
    t.string   "token"
    t.string   "cookie"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
