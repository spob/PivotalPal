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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110415013138) do

  create_table "categories", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tenant_id",  :null => false
  end

  add_index "categories", ["tenant_id"], :name => "categories_tenant_id_fk"

  create_table "logons", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "ip_address", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "logons", ["user_id"], :name => "logons_user_id_fk"

  create_table "periodic_jobs", :force => true do |t|
    t.string   "type",            :limit => 50,  :null => false
    t.string   "name",            :limit => 25,  :null => false
    t.text     "job",                            :null => false
    t.integer  "interval"
    t.datetime "last_run_at"
    t.datetime "next_run_at"
    t.integer  "run_at_minutes"
    t.string   "last_run_result", :limit => 500
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "periodic_jobs", ["last_run_at"], :name => "index_periodic_jobs_on_last_run_at"
  add_index "periodic_jobs", ["next_run_at"], :name => "index_periodic_jobs_on_next_run_at"

  create_table "pools", :force => true do |t|
    t.string   "name",                 :limit => 20, :null => false
    t.boolean  "unlimited",                          :null => false
    t.integer  "increase_rate"
    t.string   "increase_type"
    t.integer  "increase_day_number"
    t.float    "maximum_accrual_rate"
    t.integer  "accrual_day_number"
    t.integer  "tenant_id",                          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pools", ["tenant_id", "name"], :name => "index_pools_on_tenant_id_and_name", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tenants", :force => true do |t|
    t.string   "name",             :limit => 50,                :null => false
    t.integer  "users_count",                    :default => 0
    t.integer  "categories_count",               :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pools_count",                    :default => 0
  end

  add_index "tenants", ["name"], :name => "index_tenants_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tenant_id"
    t.integer  "logons_count",                        :default => 0
    t.string   "first_name"
    t.string   "last_name",                                           :null => false
    t.string   "company_name"
    t.integer  "roles_mask"
    t.integer  "manager_id"
    t.integer  "direct_reports_count",                :default => 0
    t.string   "temporary_password"
    t.date     "hired_at"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["manager_id"], :name => "users_manager_id_fk"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["tenant_id"], :name => "users_tenant_id_fk"
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  add_foreign_key "categories", "tenants", :name => "categories_tenant_id_fk", :dependent => :delete

  add_foreign_key "logons", "users", :name => "logons_user_id_fk", :dependent => :delete

  add_foreign_key "pools", "tenants", :name => "pools_tenant_id_fk", :dependent => :delete

  add_foreign_key "users", "tenants", :name => "users_tenant_id_fk", :dependent => :delete
  add_foreign_key "users", "users", :name => "users_manager_id_fk", :column => "manager_id"

end
