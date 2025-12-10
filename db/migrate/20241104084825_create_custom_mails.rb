class CreateCustomMails < ActiveRecord::Migration[7.0]
  def change
    create_table :custom_mails, id: :uuid do |t|
      t.string :doctor_id
      t.string :patient_id
      t.string :subject
      t.text :body
      t.string :status, default: 'sent'
      t.datetime :sent_at
      t.timestamps
    end
  end
end
