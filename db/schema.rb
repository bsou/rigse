# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090127220427) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "context"
    t.text     "opportunities"
    t.text     "objectives"
    t.text     "procedures_opening"
    t.text     "procedures_engagement"
    t.text     "procedures_closure"
    t.text     "assessment"
    t.text     "reflection"
    t.string   "uuid",                  :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assessment_targets", :force => true do |t|
    t.integer  "knowledge_statement_id"
    t.integer  "unifying_theme_id"
    t.integer  "number"
    t.string   "target"
    t.string   "grade_span"
    t.string   "uuid",                   :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "big_ideas", :force => true do |t|
    t.integer  "unifying_theme_id"
    t.string   "idea"
    t.string   "uuid",              :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "domains", :force => true do |t|
    t.string   "name"
    t.string   "key"
    t.string   "uuid",       :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "expectation_stems", :force => true do |t|
    t.integer  "grade_span_expectation_id"
    t.string   "stem"
    t.string   "uuid",                      :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "expectations", :force => true do |t|
    t.integer  "expectation_stem_id"
    t.string   "ordinal"
    t.string   "expectation"
    t.string   "uuid",                :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grade_span_expectations", :force => true do |t|
    t.integer  "assessment_target_id"
    t.string   "grade_span"
    t.string   "uuid",                 :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "knowledge_statements", :force => true do |t|
    t.integer  "domain_id"
    t.integer  "number"
    t.string   "statement"
    t.string   "uuid",       :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "passwords", :force => true do |t|
    t.integer  "user_id"
    t.string   "reset_code"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string  "title"
    t.integer "position"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "unifying_themes", :force => true do |t|
    t.string   "name"
    t.string   "key"
    t.string   "uuid",       :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "identity_url"
    t.string   "first_name",                :limit => 100, :default => ""
    t.string   "last_name",                 :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.string   "activation_code",           :limit => 40
    t.string   "state",                                    :default => "passive", :null => false
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
