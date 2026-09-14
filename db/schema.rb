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

ActiveRecord::Schema[8.1].define(version: 2026_09_14_125700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cv_profile_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "cv_profile_id", null: false
    t.string "file", null: false
    t.integer "number", null: false
    t.string "tag"
    t.datetime "updated_at", null: false
    t.index ["cv_profile_id", "number"], name: "index_cv_profile_versions_on_cv_profile_id_and_number", unique: true
    t.index ["cv_profile_id"], name: "index_cv_profile_versions_on_cv_profile_id"
  end

  create_table "cv_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "slug"], name: "index_cv_profiles_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_cv_profiles_on_user_id"
  end

  create_table "job_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "company", null: false
    t.string "contract_type"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "employment_type"
    t.string "expected_salary"
    t.string "link"
    t.string "offered_salary"
    t.string "position", null: false
    t.date "posted_on"
    t.string "status", default: "reviewed", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "work_mode"
    t.index ["user_id", "posted_on"], name: "index_job_applications_on_user_id_and_posted_on"
    t.index ["user_id", "status"], name: "index_job_applications_on_user_id_and_status"
    t.index ["user_id", "updated_at"], name: "index_job_applications_on_user_id_and_updated_at"
    t.index ["user_id"], name: "index_job_applications_on_user_id"
  end

  create_table "themes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file", null: false
    t.string "kind", default: "system", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["kind"], name: "index_themes_on_kind"
    t.index ["slug"], name: "index_themes_on_slug", unique: true, where: "((kind)::text = 'system'::text)"
    t.index ["user_id", "slug"], name: "index_themes_on_user_id_and_slug", unique: true, where: "((kind)::text = 'personal'::text)"
    t.index ["user_id"], name: "index_themes_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "jobseeker", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "cv_profile_versions", "cv_profiles"
  add_foreign_key "cv_profiles", "users"
  add_foreign_key "job_applications", "users"
  add_foreign_key "themes", "users"
end
