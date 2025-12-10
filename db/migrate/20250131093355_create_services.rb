class CreateServices < ActiveRecord::Migration[7.0]
  def change
    create_table :services, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :price
      t.integer :order, default: 1

      t.timestamps
    end
  end
end
