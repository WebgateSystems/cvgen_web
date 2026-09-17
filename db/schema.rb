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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "application_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "dropout_reason"
    t.string "from_status"
    t.uuid "job_application_id", null: false
    t.string "kind", null: false
    t.string "to_status"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["job_application_id", "created_at"], name: "index_application_events_on_job_application_id_and_created_at"
    t.index ["job_application_id"], name: "index_application_events_on_job_application_id"
    t.index ["user_id"], name: "index_application_events_on_user_id"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "kind", default: "employer", null: false
    t.string "legal_id"
    t.string "legal_id_kind"
    t.string "official_name", null: false
    t.string "postal_code"
    t.string "shortcut"
    t.string "street"
    t.datetime "updated_at", null: false
    t.index ["country", "legal_id_kind", "legal_id"], name: "index_companies_on_legal_identity", unique: true, where: "((legal_id IS NOT NULL) AND (legal_id_kind IS NOT NULL) AND (country IS NOT NULL))"
    t.index ["country"], name: "index_companies_on_country"
    t.index ["kind"], name: "index_companies_on_kind"
    t.index ["official_name"], name: "index_companies_on_official_name"
    t.index ["shortcut"], name: "index_companies_on_shortcut"
  end

  create_table "company_ratings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "comment"
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.integer "fairness", default: 0, null: false
    t.integer "human_process", default: 0, null: false
    t.decimal "overall", precision: 2, scale: 1, null: false
    t.integer "responsiveness", default: 0, null: false
    t.integer "seriousness", default: 0, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["company_id", "user_id"], name: "index_company_ratings_on_company_id_and_user_id", unique: true
    t.index ["company_id"], name: "index_company_ratings_on_company_id"
    t.index ["user_id"], name: "index_company_ratings_on_user_id"
  end

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
    t.text "draft_error"
    t.string "draft_status", default: "idle", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "slug"], name: "index_cv_profiles_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_cv_profiles_on_user_id"
  end

  create_table "job_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
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
    t.index ["company_id"], name: "index_job_applications_on_company_id"
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

  create_table "user_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "about"
    t.jsonb "analysis", default: {}, null: false
    t.text "analysis_error"
    t.string "analysis_status", default: "idle", null: false
    t.string "analysis_step"
    t.datetime "analyzed_at"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "location"
    t.uuid "starter_cv_profile_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["starter_cv_profile_id"], name: "index_user_profiles_on_starter_cv_profile_id"
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
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

  add_foreign_key "application_events", "job_applications"
  add_foreign_key "application_events", "users"
  add_foreign_key "company_ratings", "companies"
  add_foreign_key "company_ratings", "users"
  add_foreign_key "cv_profile_versions", "cv_profiles"
  add_foreign_key "cv_profiles", "users"
  add_foreign_key "job_applications", "companies"
  add_foreign_key "job_applications", "users"
  add_foreign_key "themes", "users"
  add_foreign_key "user_profiles", "cv_profiles", column: "starter_cv_profile_id"
  add_foreign_key "user_profiles", "users"
end
