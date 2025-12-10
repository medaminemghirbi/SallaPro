class CreateConsultationReports < ActiveRecord::Migration[7.0]
  def change
    create_table :consultation_reports, id: :uuid do |t|
      t.uuid "consultation_id", null: false
      t.text "diagnosis"
      t.text "procedures"
      t.text "prescription"
      t.text "doctor_notes"
      t.boolean "follow_up_needed", default: false    
      t.index ["consultation_id"], unique: true
    
      t.timestamps
    end
  end
end
