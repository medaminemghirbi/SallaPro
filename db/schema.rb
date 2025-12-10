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

ActiveRecord::Schema[7.0].define(version: 2025_07_11_131228) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_configs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blogs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.uuid "doctor_id", null: false
    t.uuid "maladie_id", null: false
    t.boolean "is_archived", default: false
    t.boolean "is_verified", default: false
    t.serial "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "consultation_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "consultation_id", null: false
    t.text "diagnosis"
    t.text "procedures"
    t.text "prescription"
    t.text "doctor_notes"
    t.boolean "follow_up_needed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consultation_id"], name: "index_consultation_reports_on_consultation_id", unique: true
  end

  create_table "consultations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "appointment", null: false
    t.integer "status", default: 0
    t.integer "appointment_type", default: 0
    t.boolean "is_archived", default: false
    t.uuid "doctor_id", null: false
    t.uuid "patient_id", null: false
    t.string "refus_reason"
    t.string "note"
    t.string "room_code"
    t.integer "order", default: 1
    t.boolean "is_payed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "date(appointment), doctor_id, patient_id", name: "index_consultations_on_date_and_doctor_and_patient", unique: true
  end

  create_table "custom_mails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "doctor_id"
    t.string "patient_id"
    t.string "subject"
    t.text "body"
    t.string "status", default: "sent"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "doctor_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "doctor_id", null: false
    t.uuid "service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id", "service_id"], name: "index_doctor_services_on_doctor_and_service", unique: true
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.uuid "doctor_id", null: false
    t.boolean "is_archived", default: false
    t.integer "order", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "holidays", force: :cascade do |t|
    t.string "holiday_name", null: false
    t.date "holiday_date", null: false
    t.boolean "is_archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "maladies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "maladie_name", null: false
    t.text "maladie_description"
    t.text "synonyms"
    t.text "symptoms"
    t.text "causes"
    t.text "treatments"
    t.text "prevention"
    t.text "diagnosis"
    t.text "references"
    t.serial "order"
    t.boolean "is_archived", default: false
    t.boolean "is_cancer", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.boolean "is_archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "sender_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "consultation_id", null: false
    t.string "payment_id"
    t.integer "status", default: 0
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "phone_numbers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "doctor_id", null: false
    t.string "number", null: false
    t.string "phone_type", null: false
    t.boolean "is_archived", default: false
    t.integer "order", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "predictions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "doctor_id"
    t.uuid "patient_id"
    t.string "predicted_class"
    t.string "probability"
    t.integer "download_count", default: 0
    t.uuid "maladie_id", null: false
    t.uuid "consultation_id"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ratings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "consultation_id", null: false
    t.integer "rating_value"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "price"
    t.integer "order", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "firstname"
    t.string "lastname"
    t.string "address"
    t.date "birthday"
    t.integer "gender", default: 0
    t.integer "civil_status", default: 0
    t.boolean "is_archived", default: false
    t.integer "order", default: 1
    t.string "type"
    t.string "location"
    t.string "specialization"
    t.float "latitude"
    t.float "longitude"
    t.string "description"
    t.string "code_doc"
    t.string "website"
    t.string "twitter"
    t.string "youtube"
    t.string "facebook"
    t.string "linkedin"
    t.string "phone_number"
    t.string "medical_history"
    t.integer "plan", default: 0
    t.integer "custom_limit", default: 0
    t.integer "radius", default: 5
    t.boolean "is_emailable", default: false
    t.boolean "is_notifiable", default: false
    t.boolean "is_smsable", default: false
    t.boolean "working_saturday", default: false
    t.boolean "working_on_line", default: false
    t.integer "amount"
    t.integer "plateform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language", default: "fr"
    t.string "confirmation_code"
    t.datetime "confirmation_code_generated_at"
    t.string "about_me"
    t.string "jti", default: "", null: false
    t.string "expo_push_token"
    t.boolean "is_verified", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "consultations", "users", column: "doctor_id"
  add_foreign_key "consultations", "users", column: "patient_id"
  add_foreign_key "documents", "users", column: "doctor_id"
  add_foreign_key "phone_numbers", "users", column: "doctor_id"
end
