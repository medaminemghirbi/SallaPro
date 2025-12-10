class CreatePredictions < ActiveRecord::Migration[7.0]
  def change
    create_table :predictions, id: :uuid do |t|
      t.uuid :doctor_id
      t.uuid :patient_id
      t.string :predicted_class
      t.string :probability
      t.integer :download_count, default: 0
      t.uuid :maladie_id, null: false
      t.uuid :consultation_id
      t.datetime :sent_at
      t.timestamps
    end
  end
end
