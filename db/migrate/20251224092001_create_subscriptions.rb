class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.integer :plan, null: false, default: 0
      # 0 = trial, 1 = monthly

      t.integer :status, null: false, default: 0
      # 0 = active, 1 = expired, 2 = cancelled

      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_index :subscriptions, :plan
    add_index :subscriptions, :status
  end
end
