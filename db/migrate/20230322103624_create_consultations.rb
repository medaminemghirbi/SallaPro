class CreateConsultations < ActiveRecord::Migration[7.0]
  def change
    create_table :consultations, id: :uuid do |t|
      t.datetime :appointment, null: false
      t.integer :status, default: 0
      t.integer :appointment_type, default: 0
      t.boolean :is_archived, default: false
      t.uuid :doctor_id, null: false
      t.uuid :patient_id, null: false
      t.string :refus_reason
      t.string :note
      t.string :room_code
      t.integer :order, default: 1
      t.boolean :is_payed, default: false
      t.timestamps
    end
    add_foreign_key :consultations, :users, column: :doctor_id
    add_foreign_key :consultations, :users, column: :patient_id
    add_index :consultations, 
          "DATE(appointment), doctor_id, patient_id", 
          unique: true, 
          name: "index_consultations_on_date_and_doctor_and_patient"
  end
end
