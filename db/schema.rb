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

ActiveRecord::Schema.define(version: 20150817000523) do

  create_table "posts", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.string   "link"
    t.datetime "post_creation_date"
  end

  create_table "posts_reasons", id: false, force: :cascade do |t|
    t.integer "reason_id"
    t.integer "post_id"
  end

  add_index "posts_reasons", ["post_id"], name: "index_posts_reasons_on_post_id"
  add_index "posts_reasons", ["reason_id"], name: "index_posts_reasons_on_reason_id"

  create_table "reasons", force: :cascade do |t|
    t.string "reason_name"
  end

  create_table "regexes", force: :cascade do |t|
    t.string   "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

# Could not dump table "users" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

end
