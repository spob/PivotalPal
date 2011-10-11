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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111011003154) do

  create_table "iterations", :force => true do |t|
    t.integer  "iteration_number",                    :null => false
    t.date     "start_on",                            :null => false
    t.date     "end_on",                              :null => false
    t.datetime "last_synced_at"
    t.integer  "stories_count",        :default => 0
    t.integer  "task_estimates_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id",                          :null => false
  end

  add_index "iterations", ["project_id", "iteration_number"], :name => "index_iterations_on_project_id_and_iteration_number", :unique => true

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

  create_table "projects", :force => true do |t|
    t.string   "name",                                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tenant_id",                                             :null => false
    t.datetime "last_synced_at"
    t.integer  "iterations_count",                       :default => 0
    t.integer  "pivotal_identifier",                                    :null => false
    t.integer  "iteration_duration_days"
    t.string   "sync_status",             :limit => 200
    t.datetime "next_sync_at"
  end

  add_index "projects", ["tenant_id", "name"], :name => "index_projects_on_tenant_id_and_name", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "stories", :force => true do |t|
    t.integer  "pivotal_identifier",                               :null => false
    t.string   "story_type",         :limit => 10,                 :null => false
    t.string   "url",                :limit => 50,                 :null => false
    t.integer  "points"
    t.string   "status",             :limit => 20,                 :null => false
    t.string   "name",               :limit => 200,                :null => false
    t.string   "owner",              :limit => 50
    t.integer  "sort"
    t.integer  "tasks_count",                       :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "iteration_id",                                     :null => false
  end

  add_index "stories", ["iteration_id", "pivotal_identifier"], :name => "index_stories_on_iteration_id_and_pivotal_identifier", :unique => true

  create_table "task_estimates", :force => true do |t|
    t.date     "as_of",                            :null => false
    t.float    "total_hours",                      :null => false
    t.float    "remaining_hours",                  :null => false
    t.float    "points_delivered"
    t.float    "velocity"
    t.string   "status",             :limit => 20
    t.float    "remaining_qa_hours"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "iteration_id",                     :null => false
    t.integer  "task_id"
  end

  add_index "task_estimates", ["iteration_id", "as_of"], :name => "index_task_estimates_on_iteration_id_and_as_of"
  add_index "task_estimates", ["iteration_id", "task_id", "as_of"], :name => "index_task_estimates_on_iteration_id_and_task_id_and_as_of", :unique => true
  add_index "task_estimates", ["task_id", "as_of"], :name => "index_task_estimates_on_task_id_and_as_of"

  create_table "tasks", :force => true do |t|
    t.integer  "pivotal_identifier",                                     :null => false
    t.string   "description",          :limit => 200
    t.float    "total_hours"
    t.float    "remaining_hours"
    t.string   "status",               :limit => 20
    t.boolean  "qa",                                  :default => false, :null => false
    t.integer  "task_estimates_count",                :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "story_id",                                               :null => false
  end

  add_index "tasks", ["story_id"], :name => "tasks_story_id_fk"

  create_table "tenants", :force => true do |t|
    t.string   "name",                    :limit => 50,                :null => false
    t.string   "api_key",                 :limit => 32
    t.integer  "users_count",                           :default => 0
    t.integer  "projects_count",                        :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "refresh_frequency_hours",               :default => 1, :null => false
  end

  add_index "tenants", ["name"], :name => "index_tenants_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",                           :null => false
    t.string   "encrypted_password",   :limit => 128, :default => ""
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
    t.string   "last_name",                                                                     :null => false
    t.string   "company_name"
    t.string   "api_key"
    t.integer  "roles_mask"
    t.string   "temporary_password"
    t.string   "invitation_token",     :limit => 60
    t.datetime "invitation_sent_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.string   "time_zone",            :limit => 50,  :default => "Eastern Time (US & Canada)", :null => false
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["tenant_id"], :name => "users_tenant_id_fk"
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  add_foreign_key "iterations", "projects", :name => "iterations_project_id_fk", :dependent => :delete

  add_foreign_key "logons", "users", :name => "logons_user_id_fk", :dependent => :delete

  add_foreign_key "projects", "tenants", :name => "projects_tenant_id_fk", :dependent => :delete

  add_foreign_key "stories", "iterations", :name => "stories_iteration_id_fk", :dependent => :delete

  add_foreign_key "task_estimates", "iterations", :name => "task_estimates_iteration_id_fk", :dependent => :delete
  add_foreign_key "task_estimates", "tasks", :name => "task_estimates_task_id_fk", :dependent => :delete

  add_foreign_key "tasks", "stories", :name => "tasks_story_id_fk", :dependent => :delete

  add_foreign_key "users", "tenants", :name => "users_tenant_id_fk", :dependent => :delete

end
