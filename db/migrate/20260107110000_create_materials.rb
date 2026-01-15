# frozen_string_literal: true

class CreateMaterials < ActiveRecord::Migration[7.0]
  def change
    create_table :materials, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.text :description
      t.string :serial_number
      t.string :model
      t.string :brand
      t.string :category
      t.string :status, default: 'active' # active, inactive, in_maintenance, retired
      t.string :location
      t.decimal :purchase_price, precision: 10, scale: 2
      t.date :purchase_date
      t.date :warranty_expiry_date
      t.date :next_maintenance_date
      t.integer :maintenance_interval_days
      t.jsonb :metadata, default: {}
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :assigned_to, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :materials, :serial_number
    add_index :materials, :status
    add_index :materials, :category
    add_index :materials, :next_maintenance_date
    add_index :materials, :warranty_expiry_date
  end
end
