class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments, id: :uuid do |t|
      t.uuid "consultation_id", null: false
      t.string "payment_id"
      t.integer "status", default: 0  # 0 = pending, 1 = success, 2 = failed
      t.integer "amount"
      t.timestamps
    end
  end
end
