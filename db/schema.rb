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

ActiveRecord::Schema.define(version: 20160304034338) do

  create_table "feedbacks", force: :cascade do |t|
    t.string  "message_link",  limit: 255
    t.string  "user_name",     limit: 255
    t.string  "user_link",     limit: 255
    t.string  "feedback_type", limit: 255
    t.integer "post_id",       limit: 4
    t.string  "post_link",     limit: 255
    t.integer "user_id",       limit: 4
  end

  add_index "feedbacks", ["post_id"], name: "index_feedbacks_on_post_id", using: :btree

  create_table "posts", force: :cascade do |t|
    t.string   "title",                  limit: 255
    t.text     "body",                   limit: 65535
    t.string   "link",                   limit: 255
    t.datetime "post_creation_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",                limit: 4
    t.string   "user_link",              limit: 255
    t.string   "username",               limit: 255
    t.text     "why",                    limit: 65535
    t.integer  "user_reputation",        limit: 4
    t.integer  "score",                  limit: 4
    t.integer  "upvote_count",           limit: 4
    t.integer  "downvote_count",         limit: 4
    t.integer  "stack_exchange_user_id", limit: 4
    t.boolean  "is_tp",                                default: false
    t.boolean  "is_fp",                                default: false
  end

  create_table "posts_reasons", id: false, force: :cascade do |t|
    t.integer "reason_id", limit: 4
    t.integer "post_id",   limit: 4
  end

  add_index "posts_reasons", ["post_id"], name: "index_posts_reasons_on_post_id", using: :btree
  add_index "posts_reasons", ["reason_id"], name: "index_posts_reasons_on_reason_id", using: :btree

  create_table "reasons", force: :cascade do |t|
    t.string "reason_name",     limit: 255
    t.string "last_post_title", limit: 255
  end

  create_table "sites", force: :cascade do |t|
    t.string   "site_name",   limit: 255
    t.string   "site_url",    limit: 255
    t.string   "site_logo",   limit: 255
    t.string   "site_domain", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "smoke_detectors", force: :cascade do |t|
    t.datetime "last_ping"
    t.string   "name",         limit: 255
    t.string   "location",     limit: 255
    t.string   "access_token", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.datetime "email_date"
  end

  create_table "stack_exchange_users", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.string   "username",        limit: 255
    t.datetime "last_api_update"
    t.boolean  "still_alive",                 default: true
    t.integer  "answer_count",    limit: 4
    t.integer  "question_count",  limit: 4
    t.integer  "reputation",      limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "site_id",         limit: 4
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",               limit: 255, default: "", null: false
    t.string   "encrypted_password",  limit: 255, default: "", null: false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",  limit: 255
    t.string   "last_sign_in_ip",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_approved"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
