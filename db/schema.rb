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

ActiveRecord::Schema[7.0].define(version: 2026_01_08_170001) do
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

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "key"
    t.string "resource_type"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "billing_address"
    t.boolean "active", default: true
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "categorie_id"
    t.index ["categorie_id"], name: "index_companies_on_categorie_id"
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "company_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "document_type", default: "other"
    t.string "category"
    t.bigint "file_size"
    t.string "file_type"
    t.uuid "company_id", null: false
    t.uuid "uploaded_by_id", null: false
    t.boolean "is_public", default: false
    t.datetime "expires_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_company_documents_on_category"
    t.index ["company_id"], name: "index_company_documents_on_company_id"
    t.index ["document_type"], name: "index_company_documents_on_document_type"
    t.index ["is_public"], name: "index_company_documents_on_is_public"
    t.index ["uploaded_by_id"], name: "index_company_documents_on_uploaded_by_id"
  end

  create_table "departments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "code"
    t.text "description"
    t.string "color", default: "#3B82F6"
    t.uuid "company_id", null: false
    t.uuid "manager_id"
    t.boolean "active", default: true
    t.integer "employees_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_departments_on_active"
    t.index ["code"], name: "index_departments_on_code"
    t.index ["company_id", "name"], name: "index_departments_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_departments_on_company_id"
    t.index ["manager_id"], name: "index_departments_on_manager_id"
  end

  create_table "maintenance_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "material_id", null: false
    t.uuid "performed_by_id"
    t.string "maintenance_type", null: false
    t.string "status", default: "scheduled"
    t.date "scheduled_date", null: false
    t.date "completed_date"
    t.text "description"
    t.text "notes"
    t.decimal "cost", precision: 10, scale: 2
    t.string "service_provider"
    t.jsonb "parts_replaced", default: []
    t.integer "duration_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_type"], name: "index_maintenance_records_on_maintenance_type"
    t.index ["material_id"], name: "index_maintenance_records_on_material_id"
    t.index ["performed_by_id"], name: "index_maintenance_records_on_performed_by_id"
    t.index ["scheduled_date"], name: "index_maintenance_records_on_scheduled_date"
    t.index ["status"], name: "index_maintenance_records_on_status"
  end

  create_table "materials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "serial_number"
    t.string "model"
    t.string "brand"
    t.string "category"
    t.string "status", default: "active"
    t.string "location"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.date "purchase_date"
    t.date "warranty_expiry_date"
    t.date "next_maintenance_date"
    t.integer "maintenance_interval_days"
    t.jsonb "metadata", default: {}
    t.uuid "company_id", null: false
    t.uuid "assigned_to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_materials_on_assigned_to_id"
    t.index ["category"], name: "index_materials_on_category"
    t.index ["company_id"], name: "index_materials_on_company_id"
    t.index ["next_maintenance_date"], name: "index_materials_on_next_maintenance_date"
    t.index ["serial_number"], name: "index_materials_on_serial_number"
    t.index ["status"], name: "index_materials_on_status"
    t.index ["warranty_expiry_date"], name: "index_materials_on_warranty_expiry_date"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "company_id"
    t.string "title", null: false
    t.text "message"
    t.string "notification_type", null: false
    t.string "priority", default: "normal"
    t.string "status", default: "unread"
    t.string "action_url"
    t.string "icon"
    t.string "notifiable_type"
    t.uuid "notifiable_id"
    t.datetime "read_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_notifications_on_company_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["priority"], name: "index_notifications_on_priority"
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["user_id", "status"], name: "index_notifications_on_user_id_and_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "suppliers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone_number"
    t.string "address"
    t.string "city"
    t.string "country"
    t.string "postal_code"
    t.string "contact_person"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "website"
    t.string "tax_id"
    t.string "category"
    t.text "description"
    t.text "notes"
    t.string "payment_terms"
    t.string "status", default: "active"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_suppliers_on_category"
    t.index ["company_id"], name: "index_suppliers_on_company_id"
    t.index ["email"], name: "index_suppliers_on_email"
    t.index ["name"], name: "index_suppliers_on_name"
    t.index ["status"], name: "index_suppliers_on_status"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "code"
    t.text "description"
    t.string "color", default: "#10B981"
    t.uuid "company_id", null: false
    t.uuid "department_id"
    t.uuid "leader_id"
    t.boolean "active", default: true
    t.integer "members_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_teams_on_active"
    t.index ["code"], name: "index_teams_on_code"
    t.index ["company_id", "name"], name: "index_teams_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_teams_on_company_id"
    t.index ["department_id", "name"], name: "index_teams_on_department_id_and_name"
    t.index ["department_id"], name: "index_teams_on_department_id"
    t.index ["leader_id"], name: "index_teams_on_leader_id"
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
    t.float "latitude"
    t.float "longitude"
    t.date "birthday"
    t.integer "gender", default: 0
    t.integer "civil_status", default: 0
    t.boolean "is_archived", default: false
    t.integer "order", default: 1
    t.string "type"
    t.integer "plan", default: 0
    t.string "language", default: "fr"
    t.string "jti", default: "", null: false
    t.string "phone_number"
    t.boolean "default_admin", default: false
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "company_id"
    t.uuid "department_id"
    t.uuid "team_id"
    t.string "position"
    t.date "hire_date"
    t.string "employee_id"
    t.string "status", default: "active"
    t.string "contract_type"
    t.string "work_schedule"
    t.decimal "salary", precision: 10, scale: 2
    t.text "skills", default: [], array: true
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id"], name: "index_users_on_employee_id"
    t.index ["hire_date"], name: "index_users_on_hire_date"
    t.index ["position"], name: "index_users_on_position"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  create_table "venue_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "venue_id", null: false
    t.uuid "client_id", null: false
    t.uuid "company_id", null: false
    t.uuid "created_by_id", null: false
    t.string "contract_number", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "draft"
    t.string "event_type"
    t.integer "expected_guests"
    t.datetime "event_start_date"
    t.datetime "event_end_date"
    t.decimal "base_price", precision: 10, scale: 2
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 5, scale: 2, default: "20.0"
    t.decimal "tax_amount", precision: 10, scale: 2
    t.decimal "total_amount", precision: 10, scale: 2
    t.decimal "deposit_amount", precision: 10, scale: 2
    t.boolean "deposit_paid", default: false
    t.datetime "deposit_paid_at"
    t.string "payment_method"
    t.string "payment_status", default: "pending"
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.date "valid_until"
    t.datetime "sent_at"
    t.datetime "signed_at"
    t.jsonb "selected_options", default: []
    t.jsonb "additional_services", default: []
    t.text "special_requests"
    t.text "terms_and_conditions"
    t.text "internal_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_venue_contracts_on_client_id"
    t.index ["company_id"], name: "index_venue_contracts_on_company_id"
    t.index ["contract_number"], name: "index_venue_contracts_on_contract_number", unique: true
    t.index ["created_at"], name: "index_venue_contracts_on_created_at"
    t.index ["created_by_id"], name: "index_venue_contracts_on_created_by_id"
    t.index ["event_start_date"], name: "index_venue_contracts_on_event_start_date"
    t.index ["status"], name: "index_venue_contracts_on_status"
    t.index ["venue_id"], name: "index_venue_contracts_on_venue_id"
  end

  create_table "venue_reservations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "venue_id", null: false
    t.uuid "venue_contract_id", null: false
    t.uuid "client_id", null: false
    t.uuid "company_id", null: false
    t.string "reservation_number", null: false
    t.string "status", default: "confirmed"
    t.string "event_type"
    t.integer "expected_guests"
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.decimal "deposit_amount", precision: 10, scale: 2
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0"
    t.string "payment_status", default: "pending"
    t.text "notes"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_venue_reservations_on_client_id"
    t.index ["company_id"], name: "index_venue_reservations_on_company_id"
    t.index ["end_date"], name: "index_venue_reservations_on_end_date"
    t.index ["reservation_number"], name: "index_venue_reservations_on_reservation_number", unique: true
    t.index ["start_date", "end_date"], name: "index_venue_reservations_on_start_date_and_end_date"
    t.index ["start_date"], name: "index_venue_reservations_on_start_date"
    t.index ["status"], name: "index_venue_reservations_on_status"
    t.index ["venue_contract_id"], name: "index_venue_reservations_on_venue_contract_id"
    t.index ["venue_id"], name: "index_venue_reservations_on_venue_id"
  end

  create_table "venues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "venue_type", default: "salle"
    t.integer "capacity_min", default: 0
    t.integer "capacity_max", default: 0
    t.decimal "surface_area", precision: 10, scale: 2
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "daily_rate", precision: 10, scale: 2
    t.decimal "weekend_rate", precision: 10, scale: 2
    t.string "location"
    t.string "floor"
    t.jsonb "amenities", default: []
    t.boolean "is_indoor", default: true
    t.boolean "is_outdoor", default: false
    t.boolean "has_catering", default: false
    t.boolean "has_parking", default: false
    t.integer "parking_capacity", default: 0
    t.boolean "has_sound_system", default: false
    t.boolean "has_lighting", default: false
    t.boolean "has_air_conditioning", default: false
    t.boolean "has_stage", default: false
    t.string "status", default: "available"
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["capacity_max"], name: "index_venues_on_capacity_max"
    t.index ["company_id"], name: "index_venues_on_company_id"
    t.index ["name"], name: "index_venues_on_name"
    t.index ["status"], name: "index_venues_on_status"
    t.index ["venue_type"], name: "index_venues_on_venue_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "companies", "categories", column: "categorie_id"
  add_foreign_key "companies", "users"
  add_foreign_key "company_documents", "companies"
  add_foreign_key "company_documents", "users", column: "uploaded_by_id"
  add_foreign_key "departments", "companies"
  add_foreign_key "departments", "users", column: "manager_id"
  add_foreign_key "maintenance_records", "materials"
  add_foreign_key "maintenance_records", "users", column: "performed_by_id"
  add_foreign_key "materials", "companies"
  add_foreign_key "materials", "users", column: "assigned_to_id"
  add_foreign_key "notifications", "companies"
  add_foreign_key "notifications", "users"
  add_foreign_key "suppliers", "companies"
  add_foreign_key "teams", "companies"
  add_foreign_key "teams", "departments"
  add_foreign_key "teams", "users", column: "leader_id"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "teams"
  add_foreign_key "venue_contracts", "companies"
  add_foreign_key "venue_contracts", "users", column: "client_id"
  add_foreign_key "venue_contracts", "users", column: "created_by_id"
  add_foreign_key "venue_contracts", "venues"
  add_foreign_key "venue_reservations", "companies"
  add_foreign_key "venue_reservations", "users", column: "client_id"
  add_foreign_key "venue_reservations", "venue_contracts"
  add_foreign_key "venue_reservations", "venues"
  add_foreign_key "venues", "companies"
end
