class CreatePhoneNumbers < ActiveRecord::Migration[7.0]
  def change
    create_table :phone_numbers, id: :uuid do |t|
      t.uuid :doctor_id, null: false
      t.string :number, null: false
      t.string :phone_type, null: false
      t.boolean :is_archived, default: false
      t.integer :order, default: 1

      t.timestamps
    end
    add_foreign_key :phone_numbers, :users, column: :doctor_id
  end
end
